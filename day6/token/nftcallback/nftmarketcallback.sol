// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
   
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
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
    

    constructor(address _token,address _nfttoken){
        token=IERC20(_token);
        nfttoken=IERC721(_nfttoken);
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

    function tokensReceived(address sender,uint256 amount,uint256 tokenId)public returns(bool){
        require(lists[tokenId][sender]>0,'NFT is not listed');
        require(amount >= lists[tokenId][sender], "Insufficient token amount");
        nfttoken.safeTransferFrom(nfttoken.ownerOf(tokenId), sender, tokenId);
        delete lists[tokenId][nfttoken.ownerOf(tokenId)];
        return true;
    }


}
