// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IWhitelist.sol";

contract CryptoDevs is ERC721Enumerable, Ownable {

    string _baseTokenURI;
    uint public _price = 0.01 ether;

    //_paused is used to pause the contract in case of the emergency
    bool public _paused;

    uint256 public maxTokenIds = 20;
    //total number of tokenids minted
    uint256 public tokenIds;

    IWhitelist whitelist;
    //boolen to keep track of wheter presale started or not  
    bool presaleStarted;
    //timestamp for when presale would end
    uint256 presaleEnded;

    modifier onlyWhenNotPaused {
        require(!_paused, "contract currently paused");
        _;
    }

    /**
    *   ERC721 constructor takes in a 'name' and 'symbol' to the token collection.
    *   name in our case is 'Crypto Devs' and symbol is 'CD'
    *   constructor for CryptoDevs takes in baseURL to set _baseTokenURI for the collection
    *   it also initializes an instance of IWhitelist interface 
     */
    constructor (string memory baseURI, address whitelistContract) ERC721("Crypto Devs", "CD") {
        _baseTokenURI = baseURI;
        whitelist = IWhitelist(whitelistContract);
    }

    /**
        startPresale starts a presale for the whitelisted address
     */
    function startPresale() public onlyOwner {
        presaleStarted = true;
        presaleEnded = block.timestamp + 5 minutes;
    }

    
    function presaleMint() public payable onlyWhenNotPaused {
        require(presaleStarted && block.timestamp < presaleEnded, "presale is not running");
        require(whitelist.whitelistedAddress(msg.sender), "you are not whitelisted");
        require(tokenIds < maxTokenIds, "exceeded maxmium crypto devs supply");
        require(msg.value > _price, "ether sent is not correct");
        tokenIds += 1;
        /**
        * _safeMint is a safer version of _mint function as it ensures that 
        * if the address being minted to is a contract, then it knows how to deal with ERC721 tokens
        * if the address being minted to is not a contract, it works the same way as _mint 
        */
        _safeMint(msg.sender, tokenIds);
    }

    // mint allows a user to mint 1 nft per transtration after the presale has ended
    function mint() public payable onlyWhenNotPaused {
        require(presaleStarted && block.timestamp >= presaleEnded, "presale has not ended yet");
        require(tokenIds < maxTokenIds, "exceeded maximum crypto devs supply");
        require(msg.value > _price, "ehter sent is not correct");
        tokenIds += 1;
        _safeMint(msg.sender, tokenIds);
    }

    /**
        _baseURI overrides the Opzeppelin's ERC721 implemention which by default
        retured an empty string for the baseURI  
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
        setPaused makes the contract paused or unpaused
     */
    function setPaused(bool val) public onlyOwner {
        _paused = val;
    }

    /**
        whitdraw sends all the ether in the contract
        to the owner of the contract
     */
    function withdraw() public onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent,) = _owner.call{value: amount}("");
        require(sent, "failed to sent ether");
    }

    // fucntion to recive ether. msg.data must be empty
    receive() external payable {}

    // fallback function is called when msg.data is not empty
    fallback() external payable {}

}

