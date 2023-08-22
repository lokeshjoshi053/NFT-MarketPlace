// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMarket is ReentrancyGuard, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    uint256 listingPrice = 0.025 ether;

    constructor() ERC721("YourNFTName", "NFT") {}

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;
    
    // Events
    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );
    event MarketItemSold(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address buyer,
        uint256 price
    );

    // Mint a new NFT with the provided token URI
    function mintNFT(string memory tokenURI) public {
        uint256 tokenId = _itemIds.current();
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
        _itemIds.increment();
    }

    // Place an item for sale on the marketplace
    function createMarketItem(uint256 tokenId, uint256 price) public nonReentrant {
        require(price > 0, "Price must be greater than zero");

        _itemIds.increment();
        uint256 itemId = _itemIds.current();
        _approve(address(this), tokenId);
        
        idToMarketItem[itemId] = MarketItem(
            itemId,
            address(this),
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );

        safeTransferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(
            itemId,
            address(this),
            tokenId,
            msg.sender,
            address(0),
            price,
            false
        );
    }

    // Purchase a listed NFT
    function createMarketSale(uint256 itemId) public payable nonReentrant {
        MarketItem storage item = idToMarketItem[itemId];
        require(item.price == msg.value, "Ether value sent must be equal to the item price");
        require(!item.sold, "Item is already sold");

        item.seller.transfer(msg.value);
        safeTransferFrom(address(this), msg.sender, item.tokenId);
        item.owner = payable(msg.sender);
        item.sold = true;
        _itemsSold.increment();

        emit MarketItemSold(
            itemId,
            address(this),
            item.tokenId,
            item.seller,
            msg.sender,
            item.price
        );
    }

    // Get all unsold market items
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint currentIndex = 0;
        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        
        for (uint i = 1; i <= _itemIds.current(); i++) {
            if (idToMarketItem[i].owner == address(0) && !idToMarketItem[i].sold) {
                MarketItem storage currentItem = idToMarketItem[i];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }
        return items;
    }

    // Get NFTs owned by a user
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        
        for (uint i = 1; i <= totalItemCount; i++) {
            if (idToMarketItem[i].owner == msg.sender) {
                itemCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 1; i <= totalItemCount; i++) {
            if (idToMarketItem[i].owner == msg.sender) {
                MarketItem storage currentItem = idToMarketItem[i];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }
        return items;
    }
}

