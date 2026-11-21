// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title Tri333 (T333) — 3,333 lucky-three NFTs
/// @notice ERC721 collection of 3,333 pieces. The first 2,222 are a FREE
///         pool for Binance Agent ID holders (registry balanceOf > 0),
///         max 2 free mints per wallet. The remaining 1,111 are sold in a
///         paid phase at a flat 0.00005 BNB each; the paid phase unlocks
///         only once the free pool is fully minted ("sisanya fase bayar").
///         No prize token, no reveal, no transfer restrictions: a plain,
///         standard ERC721 that any marketplace (Element included) can
///         list and any holder can send freely. Secondary sales pay a 5%
///         ERC2981 royalty to the treasury, and all collected mint BNB
///         can be withdrawn only to the treasury.
/// @notice Metadata: every token shares one metadata URI (set with
///         setMetaURI before the mint opens) carrying the collection
///         image and the official site as external_url, so indexers and
///         the AgenticMint radar detect the collection from token #1.
contract Tri333 is ERC721, ERC2981, Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 3333;
    /// @notice Hard cap of the free pool, counted by freeMinted so paid
    ///         mints can never eat into it.
    uint256 public constant FREE_CAP = 2222;
    /// @notice Free mints allowed per wallet.
    uint256 public constant FREE_PER_WALLET = 2;
    /// @notice Flat paid price per piece.
    uint256 public constant PRICE = 0.00005 ether;

    /// @notice Binance Agent ID NFT registry (ERC721). Gate = balanceOf > 0.
    IERC721 public immutable agentIdRegistry;
    /// @notice Royalty receiver and the only address mint BNB can ever be
    ///         withdrawn to.
    address public immutable treasury;

    bool public mintOpen;
    uint256 public totalMinted;
    uint256 public freeMinted;
    uint256 public paidMintedCount;

    string private _metaURI;

    /// @notice Free mints already taken per wallet (max FREE_PER_WALLET).
    mapping(address => uint256) public freeCount;

    event MintOpened(bool open);
    event FreeMint(address indexed minter, uint256 amount);
    event PaidMint(address indexed minter, uint256 amount, uint256 cost);
    event Withdrawn(address indexed to, uint256 amount);
    event MetaURISet(string metaURI);

    constructor(
        address initialOwner,
        address agentIdRegistry_,
        address treasury_
    ) ERC721("Tri333", "T333") Ownable(initialOwner) {
        require(agentIdRegistry_ != address(0), "registry zero");
        require(treasury_ != address(0), "treasury zero");
        agentIdRegistry = IERC721(agentIdRegistry_);
        treasury = treasury_;
        // 5% default royalty on secondary sales, paid to the treasury.
        _setDefaultRoyalty(treasury_, 500);
    }

    // ------------------------------------------------------------------
    // Minting
    // ------------------------------------------------------------------

    /// @notice Free mint for Binance Agent ID holders: up to
    ///         FREE_PER_WALLET per wallet while the free pool lasts.
    function freeMint(uint256 qty) external nonReentrant {
        require(mintOpen, "mint closed");
        require(qty > 0, "amount zero");
        require(freeMinted + qty <= FREE_CAP, "free cap reached");
        require(totalMinted + qty <= MAX_SUPPLY, "sold out");
        require(
            freeCount[msg.sender] + qty <= FREE_PER_WALLET,
            "free quota used"
        );
        require(agentIdRegistry.balanceOf(msg.sender) > 0, "no Agent ID");

        freeCount[msg.sender] += qty;
        freeMinted += qty;
        for (uint256 i = 0; i < qty; i++) {
            _safeMint(msg.sender, ++totalMinted);
        }
        emit FreeMint(msg.sender, qty);
    }

    /// @notice Paid mint at the flat PRICE per piece. Unlocks only once
    ///         the free pool is fully minted. Exact payment required.
    function mint(uint256 qty) external payable nonReentrant {
        require(mintOpen, "mint closed");
        require(qty > 0, "amount zero");
        require(freeMinted >= FREE_CAP, "paid phase locked");
        require(totalMinted + qty <= MAX_SUPPLY, "sold out");

        uint256 cost = PRICE * qty;
        require(msg.value == cost, "exact payment required");

        for (uint256 i = 0; i < qty; i++) {
            _safeMint(msg.sender, ++totalMinted);
        }
        paidMintedCount += qty;
        emit PaidMint(msg.sender, qty, cost);
    }

    /// @notice True once the paid phase is unlocked (free pool full).
    function paidUnlocked() public view returns (bool) {
        return freeMinted >= FREE_CAP;
    }

    // ------------------------------------------------------------------
    // Metadata
    // ------------------------------------------------------------------

    /// @notice Every token shares the single metadata URI.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return _metaURI;
    }

    function metaURI() public view returns (string memory) {
        return _metaURI;
    }

    function setMetaURI(string calldata uri) external onlyOwner {
        _metaURI = uri;
        emit MetaURISet(uri);
    }

    // ------------------------------------------------------------------
    // Admin / funds
    // ------------------------------------------------------------------

    function setMintOpen(bool open) external onlyOwner {
        mintOpen = open;
        emit MintOpened(open);
    }

    /// @notice Send the entire BNB balance to the treasury.
    ///         Callable only by the owner or the treasury itself.
    function withdraw() external nonReentrant {
        require(msg.sender == owner() || msg.sender == treasury, "not authorized");
        uint256 amount = address(this).balance;
        require(amount > 0, "nothing to withdraw");
        (bool ok, ) = treasury.call{value: amount}("");
        require(ok, "withdraw failed");
        emit Withdrawn(treasury, amount);
    }

    // ------------------------------------------------------------------
    // Interfaces
    // ------------------------------------------------------------------

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
