import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../UPRedeemer.sol";

contract NonPayableContract {
  address public up;
  address public upReedemer;

  constructor(address _up, address _upRedeemer) {
    up = _up;
    upReedemer = _upRedeemer;
  }

  function redeem() external {
    uint256 balance = ERC20(up).balanceOf(address(this));
    ERC20(up).approve(upReedemer, balance);
    UPRedeemer(payable(upReedemer)).redeem(balance);
  }
}
