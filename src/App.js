import "./App.css";
import { useState } from "react";
import { ethers } from "ethers";
import UPv2 from "./artifacts/contracts/UPv2.sol/UPv2.json";

// Update with the contract address logged out to the CLI when it was deployed
const upV2Address = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9";

function App() {
  // store name in local state
  const [UPv2, name] = useState();
  console.log(UPv2);
  console.log(name);

  // request access to the user's MetaMask account
  async function requestAccount() {
    await window.ethereum.request({ method: "eth_requestAccounts" });
  }
  requestAccount();

  // call the smart contract, read the current greeting value
  async function getName() {
    if (typeof window.ethereum !== "undefined") {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const contract = new ethers.Contract(upV2Address, UPv2, provider);
      try {
        const data = await contract.name();
        console.log("data: ", data);
      } catch (err) {
        console.log("Error: ", err);
      }
    }
  }
  getName();

  async function getBalance() {
    if (typeof window.ethereum !== "undefined") {
      const [account] = await window.ethereum.request({
        method: "eth_requestAccounts",
      });
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const contract = new ethers.Contract(upV2Address, UPv2.abi, provider);
      const balance = await contract.balanceOf(account);
      console.log("Balance: ", balance.toString());
    }
  }
  getBalance();

  // // call the smart contract, send an update
  // async function setGreeting() {
  //   if (!greeting) return;
  //   if (typeof window.ethereum !== "undefined") {
  //     await requestAccount();
  //     const provider = new ethers.providers.Web3Provider(window.ethereum);
  //     const signer = provider.getSigner();
  //     const contract = new ethers.Contract(greeterAddress, Greeter.abi, signer);
  //     const transaction = await contract.setGreeting(greeting);
  //     await transaction.wait();
  //     fetchGreeting();
  //   }
  // }

  return (
    <div className="App">
      <header className="App-header">
        <button onClick={getName}>Get Token Name</button>
        {/* <button onClick={setGreeting}>Set Greeting</button> */}
        <input
          onChange={(e) => getName(e.target.value)}
          placeholder="Get Token Name!"
        />
      </header>
    </div>
  );
}

export default App;
