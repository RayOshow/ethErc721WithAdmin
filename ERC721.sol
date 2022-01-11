
// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./AdminRole.sol";

contract ERC721 is IERC721,IERC721Metadata,AdminRole {
    
     // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    
    // token id count
    uint256 private currentTokenId = 1;
    
    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    
    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    
    // mapping from token ID to urI 
    mapping(uint256 => string) private _tokenURIs;
    
    
    
    /**
     * ERC-165
     * 
     * Send the token to other.
     * // 0x80ac58cd
     * 
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ;
            //super.supportsInterface(interfaceId);
    }
    
    
    /**
     * ERC-721
     * 
     * Get balance.
     * 
     */
    function balanceOf(address owner) external view virtual override returns (uint256 balance) {
        return _balances[owner];
    }
    
    /**
     * ERC-721
     * 
     * Check the owner 
     * 
     */    
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

   
    /**
     * ERC-721
     * 
     * Allow other to control the token.
     * 
     */
    function approve(address to, uint256 tokenId) external virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }
    

    /**
     * ERC-721
     * 
     * Send the token to other.
     * 
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
        
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }
    
    /**
     * ERC-721
     * 
     * get the address got approved for the token.
     * 
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

 
    /**
     * ERC-721
     * 
     * set if the operator can control msg.sender's assets. 
     * 
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(msg.sender != operator, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    
    /**
     * ERC-721
     * 
     * get whether operator is permitted.
     * 
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }


    /**
     * ERC-721
     * 
     *  Safe transfe
     * 
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        require(_checkOnERC721Received(msg.sender, to, tokenId, ""), "ERC721: transfer to non ERC721Receiver implementer");
        _transfer(from, to, tokenId);
    }
    
    /**
     * ERC-721
     * 
     *   Safe transfer with data to reciever contract.
     * 
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) virtual override external {
         require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
         require(_checkOnERC721Received(msg.sender, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
         _transfer(from, to, tokenId);
    }


    /**
     *  ERC-721Metadata
     *   token Name
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     *  ERC-721Metadata
     * 
     *  token symbol
     *  
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
   
    /**
     *  ERC-721Metadata
     * 
     *  token symbol
     *  
     */    
    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        
        return _tokenURIs[tokenId];
    }



    /**
     *  ERC-721Metadata
     * 
     *  token symbol
     *  
     */ 
    function safeMint(address to, string memory url) public onlyMinter {
               
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(currentTokenId), "ERC721: token already minted");
        
         require(
            _checkOnERC721Received(address(0), to, currentTokenId, ""),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
        
        _balances[to] += 1;
        _owners[currentTokenId] = to;
        
        _tokenURIs[currentTokenId] = url;

        currentTokenId++;

        emit Transfer(address(0), to, currentTokenId);
    }


    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
    
    
    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    
    
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        
        return size > 0;
    }
    
    
    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    
    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }
    
    

}


// Token main contract
contract token is ERC721 {
    string public constant _name = "rayee";
    string public constant _symbol = "RAY";

    constructor() ERC721(_name, _symbol){
        
    }
}


