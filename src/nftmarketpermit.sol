// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
   
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function permit(address holder, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract NftMarket{
    IERC20 public token;
    IERC721 public nfttoken;
    mapping (uint=>mapping(address=>uint))lists;
    address public owner;
    mapping(address => bool) public whitelist;
    mapping(bytes32 => bool) public usedSignatures;

    event AddedToWhitelist(address indexed user);
    

    constructor(address _token,address _nfttoken){
        token=IERC20(_token);
        nfttoken=IERC721(_nfttoken);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyWhitelisted(address user) {
        require(whitelist[user], "Not whitelisted");
        _;
    }

    function addToWhitelist(address user) external onlyOwner {
        whitelist[user] = true;
        emit AddedToWhitelist(user);
    }


    function list(uint256 tokenId,uint256 price)public {
        require(nfttoken.ownerOf(tokenId)==msg.sender,"You are not the owner of this NFT");
        require(nfttoken.getApproved(tokenId) == address(this), "Marketplace is not approved");
        lists[tokenId][msg.sender]=price;
    }

    function buyNFT(uint256 buyamount,uint256 tokenId) public{
        require(buyamount==lists[tokenId][nfttoken.ownerOf(tokenId)],"the price mot match");
        require(token.balanceOf(msg.sender)>=lists[tokenId][msg.sender],'Insufficient token balance');
        token.transferFrom(msg.sender, nfttoken.ownerOf(tokenId), buyamount);
        nfttoken.transferFrom(nfttoken.ownerOf(tokenId), msg.sender, tokenId);
        delete lists[tokenId][nfttoken.ownerOf(tokenId)];
    }

    function permitBuy(
        uint256 tokenId,
        uint256 value,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS, 
        uint8 v, 
        bytes32 r, 
        bytes32 s)public{
        // Generate the message hash
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, tokenId));
        
        // Reconstruct the signed message hash
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );

        // Recover the signer address
        address signer = ecrecover(ethSignedMessageHash, v, r, s);
        
        // Ensure the signer is the owner and the signature hasn't been used before
        require(signer == owner, "Invalid signature");
        require(!usedSignatures[ethSignedMessageHash], "Signature already used");

        // Mark this signature as used
        usedSignatures[ethSignedMessageHash] = true;

        // Ensure the buyer is whitelisted
        require(whitelist[msg.sender], "Not whitelisted");

        // Execute the buy process (add your buy logic here)
        token.permit(msg.sender,address(this),value,deadline,permitV,permitR,permitS);
        buyNFT(value,tokenId);
    }


}