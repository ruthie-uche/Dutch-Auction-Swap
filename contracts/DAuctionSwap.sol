// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract DutchAuctionSwap is ReentrancyGuard {
    struct Auction {
        address seller;
        IERC20 token;
        uint256 amount;
        uint256 initialPrice;
        uint256 startTime;
        uint256 duration;
        uint256 priceDecayRate;
        bool active;
    }

    Auction public auction;
    address public buyer;

    event AuctionCreated(
        address indexed seller,
        address indexed token,
        uint256 amount,
        uint256 initialPrice,
        uint256 startTime,
        uint256 duration,
        uint256 priceDecayRate
    );

    event AuctionFinalized(address indexed buyer, uint256 finalPrice);

    modifier onlySeller() {
        require(msg.sender == auction.seller, "Not the seller");
        _;
    }

    modifier auctionActive() {
        require(auction.active, "No active auction");
        _;
    }

    function createAuction(
        IERC20 _token,
        uint256 _amount,
        uint256 _initialPrice,
        uint256 _duration
    ) external {
        require(!auction.active, "Auction already active");
        require(_duration > 0, "Invalid duration");

        auction = Auction({
            seller: msg.sender,
            token: _token,
            amount: _amount,
            initialPrice: _initialPrice,
            startTime: block.timestamp,
            duration: _duration,
            priceDecayRate: _initialPrice / _duration,
            active: true
        });

        require(
            _token.transferFrom(msg.sender, address(this), _amount),
            "Token transfer failed"
        );

        emit AuctionCreated(
            msg.sender,
            address(_token),
            _amount,
            _initialPrice,
            block.timestamp,
            _duration,
            auction.priceDecayRate
        );
    }

    function getCurrentPrice() public view auctionActive returns (uint256) {
        uint256 elapsedTime = block.timestamp - auction.startTime;
        if (elapsedTime >= auction.duration) {
            return 0;
        }
        return auction.initialPrice - (elapsedTime * auction.priceDecayRate);
    }

    function buy() external payable nonReentrant auctionActive {
        uint256 currentPrice = getCurrentPrice();
        require(msg.value >= currentPrice, "Insufficient ETH sent");

        auction.active = false;
        buyer = msg.sender;

        payable(auction.seller).transfer(currentPrice);
        auction.token.transfer(msg.sender, auction.amount);

        emit AuctionFinalized(msg.sender, currentPrice);
    }
}
