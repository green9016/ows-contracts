// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./interfaces/ILayerZeroReceiver.sol";
import "./interfaces/ILayerZeroEndpoint.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract OmnichainNFT is ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl, ILayerZeroReceiver {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;
    ILayerZeroEndpoint public endpoint;

    constructor(string memory name_, string memory symbol_, address _layerZeroEndpoint) ERC721(name_, symbol_) {
        endpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
        _setupRole(DEFAULT_ADMIN_ROLE, address(this));
        _setupRole(MINTER_ROLE, address(endpoint));
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function safeMint(address to, string memory uri) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // send a NFT to another chain.    
    // this function sends a NFT from your address to the same address on the destination.
    function sendNFT(
        uint16 _chainId,                            // send tokens to this chainId
        bytes calldata _dstOmnichainNFTAddr,       // destination address of OmnichainNFT
        uint _id                                    // id of the NFT to send
    )
        public
        payable
    {
        // // burn the tokens locally.
        // // tokens will be minted on the destination.
        require(
            _isApprovedOrOwner(msg.sender, _id),
            "You need to approve or be owner of the contract to send your NFTs!"
        );
        
        // saving the uri of the token to send it across the chains
        string memory uri = tokenURI(_id);
        // burn the NFT
        _burn(_id); // *poof*

        // abi.encode() the payload with the values to send
        bytes memory payload = abi.encode(msg.sender, uri);

        // send LayerZero message
        endpoint.send{value:msg.value}(
            _chainId,                       // destination chainId
            _dstOmnichainNFTAddr,          // destination address of OmnichainNFT
            payload,                        // abi.encode()'ed bytes
            payable (msg.sender),                     // on destination send to the same address as the caller of this function
            address(0x0),                   // 'zroPaymentAddress' unused for this mock/example
            bytes("")                       // 'txParameters' unused for this mock/example
        );
    }

    // receive the bytes payload from the source chain via LayerZero
    // _fromAddress is the source OmnichainNFT address
    function lzReceive(uint16 _srcChainId, bytes memory _fromAddress, uint64 _nonce, bytes memory _payload) override external{
        require(msg.sender == address(endpoint)); // boilerplate! lzReceive must be called by the endpoint for security

        // decode
        (address toAddr, string memory uri) = abi.decode(_payload, (address, string));

        // mint the NFT back into existence, to the toAddr from the message payload with the same uri
        safeMint(toAddr, uri);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}