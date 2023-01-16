// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";

contract FTTGovernor is Governor, GovernorSettings, GovernorCountingSimple, GovernorVotes {
    constructor(IVotes _token)
        Governor("FTTGovernor")
        GovernorSettings(1 /* 1 block */, 17280 /* 1 days */, 1000e18)
        GovernorVotes(_token)
    {}

    function quorum(uint256 blockNumber) public pure override returns (uint256) {
        return 500000e18;
    }

    // The following functions are overrides required by Solidity.

    function votingDelay()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }
}