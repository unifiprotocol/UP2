// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./UPMintPublic.sol";

/// @title UPWhitelistedMint
/// @author dxffffff & A Fistful of Stray Cat Hair & Kerk
/// @notice This contract allows to mint UP for a bunch of whitelisted addresses.

contract UPWhitelistedMint is UPMintPublic {
  mapping(address => bool) public whiteListedAddress;
  event WhiteListAdded(address _account);
  event WhiteListRemoved(address _account);

  constructor(
    address _UP,
    address _UPController,
    uint256 _mintRate,
    address _fundsTarget
  ) UPMintPublic(_UP, _UPController, _mintRate, _fundsTarget) {
    preLoadData();
  }

  modifier onlyWhitelisted() {
    require(whiteListedAddress[msg.sender] == true, "UPWhitelistedMint: ONLY_WHITELISTED");
    _;
  }

  /// @notice Payable function that mints UP at the mint rate, deposits the native tokens to the UP Controller, Sends UP to the Msg.sender
  /// @param to Destination address for minted tokens
  function mintUP(address to) public payable override onlyWhitelisted {
    super.mintUP(to);
  }

  function addWhiteListed(address[] memory account) public onlyAdmin {
    uint256 i = 0;
    while (i < account.length) {
      whiteListedAddress[account[i]] = true;
      emit WhiteListAdded(account[i]);
      i++;
    }
  }

  function removeWhiteListed(address[] memory account) public onlyAdmin {
    uint256 i = 0;
    while (i < account.length) {
      whiteListedAddress[account[i]] = false;
      emit WhiteListRemoved(account[i]);
      i++;
    }
  }

  function preLoadData() internal {
    //sample data
    whiteListedAddress[0x4Fa62Ce3Faac2327F0F795256aB87BD9DFC2660A] = true;
    whiteListedAddress[0x1D762d59e67c6783837B550599E576960Ac31397] = true;
    whiteListedAddress[0x8C431639E1cb4c26c6a338f234C4cb7500DFa417] = true;
    whiteListedAddress[0x039E4a6d9633fa330918b1E6dC8183085C9E9b1e] = true;
    whiteListedAddress[0x03F9F1f03A2181B1bf0324977222488997dA0BA0] = true;
    whiteListedAddress[0x043027C0d28a1544AB43b3aaDeba8114Bbaaea54] = true;
    whiteListedAddress[0x0689F49d52d0B72911CC123587d4132f38DD37c1] = true;
    whiteListedAddress[0x09e6a264894beEfEaAB757196826f7C42B4B3f3f] = true;
    whiteListedAddress[0x0b8b2A4996627F9bF106E7b6d9540f1266841957] = true;
    whiteListedAddress[0x0ed6A892e46D8F1966FC5652AB4927bb1E1029b5] = true;
    whiteListedAddress[0x14F45114acbF4F1090FaB1301b483aF09BEAE3c3] = true;
    whiteListedAddress[0x169F9Dbbfa69cBF8E4ea8ddA4E924F353A5f1b6d] = true;
    whiteListedAddress[0x1d02d8180a0Aa69F15Be2e2d7aC8ec769A01B259] = true;
    whiteListedAddress[0x00449b56C56Af4D209F10D21104Ce5949A88dF07] = true;
    whiteListedAddress[0x1fbCA35449fEdDB0A34438FD29A64063b420f125] = true;
    whiteListedAddress[0x206d8456E3731e0c9a664EAA41e6606251fE6e59] = true;
    whiteListedAddress[0x244f29a1CDaf9f446cbBc90a4186C8407f253a4e] = true;
    whiteListedAddress[0x305532a9e75F09815b3bf2e49f93218F2dAc9E57] = true;
    whiteListedAddress[0x307996195526EB00A1F960b937b1a691eBC63948] = true;
    whiteListedAddress[0x312b9976993f7eb384Cdbd02784b1B698b61D0Ac] = true;
    whiteListedAddress[0x320Cb3Ca1a5aca613cbe7Bd904681964D8Ab54e6] = true;
    whiteListedAddress[0x3497A4d6c5b9b744c2599834fBE6FAF0cf8aFae0] = true;
    whiteListedAddress[0x39E8BE0249937e2aD11B479f063b17d05DE7CEeF] = true;
    whiteListedAddress[0x3B1a808b6992Dc6338b9E68b8A11Ac3E5a59D21e] = true;
    whiteListedAddress[0x3D68eb06Aa27784b75aC8D6FeE311CDa0F22B528] = true;
    whiteListedAddress[0x3E02cbb90C223543D8FEA9D04F42B78B6617283F] = true;
    whiteListedAddress[0x408E2B2F7770A6DD53F52C5248633aF93aC30aF9] = true;
    whiteListedAddress[0x46ddA2A36e9159FE97723a5E4a465d57D6334E18] = true;
    whiteListedAddress[0x47Ab81f131fAffe867393c45F4c6435C868DfCC4] = true;
    whiteListedAddress[0x4adaFC1863E231869Dc57A7f09372812c212774C] = true;
    whiteListedAddress[0x4ae520B54b48F1f91b8f2158726E58468654BB14] = true;
    whiteListedAddress[0x4CE06672C1c0086C29303A40951Ed54E68Dfab12] = true;
    whiteListedAddress[0x52F8E27FD525b22D7247D9db6b561A57980dbf3f] = true;
    whiteListedAddress[0x53857A3468c26D3A01608353ab431540c38E55fB] = true;
    whiteListedAddress[0x54196a9B19C00FA050D7eAA3635166A7b4B151b6] = true;
    whiteListedAddress[0x5869CE67f59590752c5e59aFE6668134f5A1BF52] = true;
    whiteListedAddress[0x5A098c73D4392062072F68775784a27965c93270] = true;
    whiteListedAddress[0x5Abd6E8A9cAA16eCD1ff5BEF0452E73Fca56e198] = true;
    whiteListedAddress[0x5B4332117F6aee20bEFa304b7EFB82865D9e15a4] = true;
    whiteListedAddress[0x5bbce4F501Dd6664278793683423317987cB5a28] = true;
    whiteListedAddress[0x5f8aBeD13Be8f92a5B5998459B790CAf120F5B23] = true;
    whiteListedAddress[0x612fEAf8C5eeEB46643d7f88C8761379515ED17A] = true;
    whiteListedAddress[0x617573B6456Ea15a1eb515A3119ABb19bdC10d52] = true;
    whiteListedAddress[0x62F55a4513bC8F10a006011bf34325B5EB1aFbF6] = true;
    whiteListedAddress[0x67536B45Ee668C0063Ff77df2539A7F6f91eD789] = true;
    whiteListedAddress[0x686934e36F4944F527d1d58Abcc90F52D67537C8] = true;
    whiteListedAddress[0x6aCf93D1e0c4cbC15B62fA162346Ac4505c94390] = true;
    whiteListedAddress[0x6D8fcfB4915C6e4471E6f12d8CEca54D1671bd1b] = true;
    whiteListedAddress[0x6FA062c9d58691eBE887ab961aFBd07791Bb2410] = true;
    whiteListedAddress[0x730B1f8222622493F7b50D4588583facAB40BacC] = true;
    whiteListedAddress[0x73F72CB9F5ac80Fa6a763823998956e734DFF980] = true;
    whiteListedAddress[0x790C57FCd83fAC182EA922506cd558d5C2e653fB] = true;
    whiteListedAddress[0x7A5F2b8C528a2271503be40462934C5ad145F1b9] = true;
    whiteListedAddress[0x7EA6BfD04A2108c51F3f5fF0D4824F8bB6c9Ce4F] = true;
    whiteListedAddress[0x80555184B3A032053Bd7C5B31810f8dda7508Ad3] = true;
    whiteListedAddress[0x825fd7B75a06C0949Fd297AB131a8eBC73BFB5Fc] = true;
    whiteListedAddress[0x854b379CA17baeBE687309db284F89BaC3d50B1f] = true;
    whiteListedAddress[0x0169B7A047510bb35C1a49B10e3D3Fcf692116F5] = true;
    whiteListedAddress[0x8FACDA5C01ee516C2D2A09AE2f2a372f340151E3] = true;
    whiteListedAddress[0x931E41Ffc6198a43a82eDe4a621FFB0eFB1BE6C7] = true;
    whiteListedAddress[0x9372f78cd9776FF48A33f93394400559a59cE191] = true;
    whiteListedAddress[0x94b6DcF72Ecaae9CE0f2a00188E26f5391993E94] = true;
    whiteListedAddress[0x987EbeD92EC52D83DF9da87844B7FCeb10dE484F] = true;
    whiteListedAddress[0x9b0D1fBfA61e4859B3Dc0d21fb312ba9E08C5B98] = true;
    whiteListedAddress[0x9bb64e40DCBe4645F99F0a9e2507b5A53795fa70] = true;
    whiteListedAddress[0xa86d3Ca8b52874fdc6938663d6ae5F8924635653] = true;
    whiteListedAddress[0xA924F6633abc981f5f00435014F84cb05aBE46c2] = true;
    whiteListedAddress[0xAb7Bb04B3e49c8B5bFd7f8D2A20a3f947c1d5Bb9] = true;
    whiteListedAddress[0xaBd151d06e927A3DDcd5c1CE64982e94813582ea] = true;
    whiteListedAddress[0xAEfa7ac3Ec9CBb78228278fB01A37F262Ae389d2] = true;
    whiteListedAddress[0xAF2BbdC320B66DB8c753e18fEd31Cc088ED52B09] = true;
    whiteListedAddress[0xb4B850939B9d82b881a275c4f4B1ffaE6a36D834] = true;
    whiteListedAddress[0xB57DCEBD2230b47759ef9eBD399d4D327beCf99F] = true;
    whiteListedAddress[0xb730525E761d7046c20553eA6d6B28383fa950e3] = true;
    whiteListedAddress[0xb881FCB2e06615BEda2eD674cfaF415E79EEF647] = true;
    whiteListedAddress[0xb895C8A0C3786F028865116b502895b2951d9968] = true;
    whiteListedAddress[0xbc472bF9cB0d8B70c50f27ED66b62c899757294A] = true;
    whiteListedAddress[0xBEAC648b23160b3Ae5d55364aD5f20d83187e50d] = true;
    whiteListedAddress[0xC94cFBeF9d51d0de9916A6565255A46230Aa701c] = true;
    whiteListedAddress[0xcaa15e4b6CA6863750229Ef6Ae039C4Da99989D8] = true;
    whiteListedAddress[0xcc9C7497b760b691962bbeB743D45Fa964c0d3e1] = true;
    whiteListedAddress[0xcEaE06e7d4aee7d00224e9c31a7F4CEfED5B4ac9] = true;
    whiteListedAddress[0xD04cA578aDd6F7002EDd8730A6823efDF7dC0DA6] = true;
    whiteListedAddress[0xdAaEDA07BB101b98E52BB37e2Edcf25fB8Dc99EC] = true;
    whiteListedAddress[0xdbE0FC262CbcA3eC4C0335B1EA35930f1ec5207b] = true;
    whiteListedAddress[0xdE460a17e1181855dC34Ad801D9652CF41FBE2D8] = true;
    whiteListedAddress[0xdF2476Cf8A78F53f0a13b22802140dc25D587dF6] = true;
    whiteListedAddress[0xE5410Bf67a811bFaFFca10e96776092403b4cFCB] = true;
    whiteListedAddress[0xE66Ca5Ba64Da211535079D6E3c8ff696f889A285] = true;
    whiteListedAddress[0xE68C82a409ACb35606f74C5f908D6756F44F9E34] = true;
    whiteListedAddress[0xe7DAdc993C6c67274c69fCf1475A05F8b628fd93] = true;
    whiteListedAddress[0xE82a43687829D003b91250f041bA22163ba6eaC1] = true;
    whiteListedAddress[0xE9558428D24088d2D250Fa69aB1205BEC805b683] = true;
    whiteListedAddress[0xEC09020811060215690501aAb132cDA57f5DA749] = true;
    whiteListedAddress[0xEf64c4C06D4D1063DD3071d707255aA529cB4DD2] = true;
    whiteListedAddress[0xEfDdD1320Ca76C97f68bFF4501442e367d42462C] = true;
    whiteListedAddress[0xf3f5870c497c53Dfab4cCA55263D4c446e1d611F] = true;
    whiteListedAddress[0xF5F8bF6Ef17E256f4E7bB2Fd7bF37056753F9706] = true;
    whiteListedAddress[0xfafe26Ba178460840d30C9Da63083cfA37b2f506] = true;
    whiteListedAddress[0xFfE29A89C059048aFCc17B60Dd37402952783255] = true;
  }
}
