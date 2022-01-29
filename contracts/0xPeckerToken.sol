// contracts/LeaseToken.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title HexPeckerToken: leasing token for accessing base.101.cy
/// @custom:security-contact marios@101.cy
contract HexPeckerToken is ERC721 {

    // Counter for incremental tokenIds
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Address of the DAO.101.cy membership token contract on Rinkeby
    address constant DAOTokenContract = address(0xE4786c3289F3F3fFac1C75C92C0c03B56fA4f25F);

    // Interface for DAO membership tokens -- Aragon Chainlink tokens
    IERC20 DAOTokenInterface = IERC20(DAOTokenContract);

    struct lockPeriod {
        uint256 tokenId;
        uint256 since;
        uint256 until;
    }

    mapping (address => lockPeriod[]) public lockedMembers;

    constructor() ERC721("0xPecker", "0xPKR") {}

    function isMemberLocked(address member, uint256 since, uint256 until) public returns (bool) {
        lockPeriod[] memory memberLocks = lockedMembers[member];
        if (memberLocks.length == 0) {
            // There is no entry for this member
            return false;
        }

        //TODO: Iterate memberLocks

        if (memberLock[until] < block.timestamp) {
            // An older entry for this member that has expired, delete
            return false;
        }
        
        //TODO: Check overlaps

        return true;
    }

    function getTokenById(uint256 tokendId) external {
    }

    // Mint 0xPecker sublet token for DAOTokenId, since, until, to recipient
    // since and until are UNIX epochs
    function safeMint(uint256 since, uint256 until, address to) public {

        if (since > until) revert(); // The since timestamp needs to be before the until timestamp

        if (until < block.timestamp) revert(); // Given until timestamp is in the past

        if (isMemberLocked(msg.sender, since, until)) revert(); // An existing period overlaps with given since/until

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        lockedMembers[msg.sender].push(lockPeriod(tokenId, since, until)); // Lock member for that period

        //TODO: What happens to 0xPecker tokens after members burns/transfers their DAO token?
    }


}