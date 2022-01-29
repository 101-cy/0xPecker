// contracts/0xPeckerToken.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title HexPeckerToken: sublet token for accessing base.101.cy
/// @custom:security-contact marios@101.cy
contract HexPeckerToken is ERC721 {

    // Counter for incremental tokenIds
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Address of the DAO.101.cy membership token contract on Rinkeby
    // https://client.aragon.org/#/rinkeby101cy.aragonid.eth
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

    function isMemberLocked(address member, uint256 since, uint256 until) public view returns (bool) {
        lockPeriod[] memory memberLocks = lockedMembers[member];
        
        // Iterate memberLocks
        for (uint i = 0; i < memberLocks.length; i++) {
            if (memberLocks[i].until < block.timestamp) {
                // An older entry for this member that has expired, delete
                //TODO: memberLocks.remove(i);
                continue;
            }
            if (since <= memberLocks[i].until && memberLocks[i].since <= until) {
                return true;
            }
        }

        return false;
    }

    function getTokenStatus(uint256 tokendId) external pure returns (address member, uint256 since, uint256 until) {
        //TODO: What happens to 0xPecker tokens after members burn/transfer their DAO token?
    }

    // Mint 0xPecker sublet token for DAOTokenId, since, until, to recipient
    // since and until are UNIX epochs
    function safeMint(uint256 since, uint256 until, address to) public {
        if (DAOTokenInterface.balanceOf(msg.sender) < 1) revert(); // Sender does not have a DAO membership token

        if (since > until) revert("The since timestamp needs to be before the until timestamp");

        if (until < block.timestamp) revert("Given until timestamp is in the past");

        if (isMemberLocked(msg.sender, since, until)) revert("An existing period overlaps with given since/until");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        lockedMembers[msg.sender].push(lockPeriod(tokenId, since, until)); // Lock member for that period
    }


}