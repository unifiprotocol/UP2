//   it('Should set a new "mintRate"', async () => {
//     await upController.setMintRate(10)
//     expect(await upController.mintRate()).equal(10)
//   })

//   it('Shouldn\'t set a new "mintRate" because not enough permissions', async () => {
//     const [, addr2] = await ethers.getSigners()
//     const addr2UpController = upController.connect(addr2)
//     await expect(addr2UpController.setMintRate(10)).revertedWith("Ownable: caller is not the owner")
//   })

// it("Should mint UP at premium rates #1", async () => {
//     await addr1.sendTransaction({
//       to: upController.address,
//       value: ethers.utils.parseEther("5")
//     })
//     await upToken.mint(upController.address, ethers.utils.parseEther("2"))
//     await upController.mintUP({ value: ethers.utils.parseEther("100") })
//     expect(await upToken.balanceOf(addr1.address)).equal(ethers.utils.parseEther("237.5"))
//   })

//   it("Should mint UP at premium rates #2", async () => {
//     await addr1.sendTransaction({
//       to: upController.address,
//       value: ethers.utils.parseEther("5")
//     })
//     await upToken.mint(upController.address, ethers.utils.parseEther("2"))
//     await upController.mintUP({ value: ethers.utils.parseEther("31") })
//     expect(await upToken.balanceOf(addr1.address)).equal(ethers.utils.parseEther("73.625"))
//   })

//   it("Should mint UP at premium rates #3", async () => {
//     await addr1.sendTransaction({
//       to: upController.address,
//       value: ethers.utils.parseEther("5")
//     })
//     await upToken.mint(upController.address, ethers.utils.parseEther("2"))
//     await upController.mintUP({ value: ethers.utils.parseEther("1233") })
//     expect(await upToken.balanceOf(addr1.address)).equal(ethers.utils.parseEther("2928.375"))
//   })

//   it("Should mint UP at premium rates #4", async () => {
//     await addr1.sendTransaction({
//       to: upController.address,
//       value: ethers.utils.parseEther("5")
//     })
//     await upToken.mint(upController.address, ethers.utils.parseEther("2"))
//     await upController.mintUP({ value: ethers.utils.parseEther("999.1") })
//     expect(await upToken.balanceOf(addr1.address)).equal(ethers.utils.parseEther("2372.8625"))
//   })

//   it("Should mint UP at premium rates #5", async () => {
//     await network.provider.send("hardhat_setBalance", [
//       addr1.address,
//       ethers.utils.parseEther("99900").toHexString()
//     ])
//     await addr1.sendTransaction({
//       to: upController.address,
//       value: ethers.utils.parseEther("5")
//     })
//     await upToken.mint(upController.address, ethers.utils.parseEther("2"))
//     await upController.mintUP({ value: ethers.utils.parseEther("91132.42") })
//     expect(await upToken.balanceOf(addr1.address)).equal(ethers.utils.parseEther("216439.4975"))
//   })

//   it("Should fail minting UP because payable value is zero", async () => {
//     await expect(upController.mintUP({ value: 0 })).revertedWith("INVALID_PAYABLE_AMOUNT")
//   })

//   it("Should mint zero UP because virtual price is zero", async () => {
//     await upController.mintUP({ value: ethers.utils.parseEther("100") })
//     expect(await upToken.balanceOf(addr1.address)).equal(0)
//   })

//   it("Shouldn't mint up because contract is paused", async () => {
//     await upController.pause()
//     await expect(upController.mintUP({ value: ethers.utils.parseEther("100") })).revertedWith(
//       "Pausable: pause"
//     )
//   })
