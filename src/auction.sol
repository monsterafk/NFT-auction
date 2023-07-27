// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.17;

import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTAuction is ERC721{
    ERC721 nftAddress;
    uint128 tokenId;

    address public ownerAuction;

    uint64 finishAfterBid = 86400;
    uint256 auctionStarted;
    uint256 auctionFinish;

    uint256 minBid;
    uint256 highestBid;
    address highestBidder;

    event AuctionStarted(uint256 timeStart, uint256 timeEnd);
    event BidPlaced(address bidder, uint256 bid, uint256 auctionFinish);

    mapping(address => uint) rates;

    modifier onlyOwnerAuction(){
        require(msg.sender == ownerAuction);
        _;
    }

    constructor() ERC721("Ff", "gg"){
        ownerAuction = msg.sender;
    }


    function startAuction(uint256 timeToFinish, uint256 minimalBid) external onlyOwnerAuction {
        require(address(nftAddress) != address(0), "Don't have NFT for auction");

        auctionFinish = timeToFinish;
        auctionStarted = block.timestamp;
        minBid = minimalBid;
        
        emit AuctionStarted(block.timestamp, auctionFinish);
    }

    function giveNFT(address nft, uint128 id, address from) external onlyOwnerAuction {
        require(nft != address(0), "Address can't be zero");

        nftAddress = ERC721(nft);
        tokenId = id;

        // nftAddress.approve(address(this), tokenId);
        nftAddress.transferFrom(from, address(this), tokenId);
    }

    function bid() external payable {
        require(msg.sender != ownerAuction);
        require(msg.value > minBid && msg.value > highestBid, "bid should be higher");
        require(block.timestamp >= auctionStarted && block.timestamp <= auctionFinish);

        highestBid = msg.value;
        highestBidder = msg.sender;
        rates[msg.sender] = msg.value;

        auctionFinish = block.timestamp + finishAfterBid;

        emit BidPlaced(msg.sender, highestBid, auctionFinish);
    }

    function getHighestInfo() external view returns(address, uint){
        return (highestBidder, highestBid);
    }

    function claimETH() external {
        require(block.timestamp >= auctionFinish, "Wait end");
        require(rates[msg.sender] > 0, "You don't have bid");
        require(msg.sender != highestBidder, "You can't do this");
        
        uint256 valueETH = rates[msg.sender];

        (bool success, ) = (msg.sender).call{value: valueETH}("");
        require(success);
    }

    function claimNFT() external {
        require(msg.sender != ownerAuction);
        require(msg.sender == highestBidder, "Only highestBidder can do this");
        require(block.timestamp >= auctionFinish, "Wait end");

        nftAddress.transferFrom(address(this), msg.sender, tokenId);
    }
}