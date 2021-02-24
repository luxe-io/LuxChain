var luxChain = artifacts.require("./LuxChain.sol");

contract('LuxChain', function (accounts) {

    before(async () => {
        this.luxChain = await luxChain.deployed()
    })

    it('Deploys successfully', async () => {
        const address = await this.luxChain.address
        assert.notEqual(address, 0x0)
        assert.notEqual(address, '')
        assert.notEqual(address, null)
        assert.notEqual(address, undefined)
        console.log("TEST")
    })

    it('TestContract balance should starts with 0 ETH', async () => {
        let balance = await web3.eth.getBalance(this.luxChain.address);
        assert.equal(balance, 0);
    })

    it('TestContract balance should has ETH after deposit', async () => {
        let eth = web3.utils.toWei("1");
        await web3.eth.sendTransaction({from: accounts[0], to: this.luxChain.address, value: eth});
        let balance_ether = await web3.eth.getBalance(this.luxChain.address);
        assert.equal(balance_ether, 1000000000000000000);
    })

    it('Add company working correctly', async () => {
        await this.luxChain.addCompany('0xd2AbAC814219E6d9128ffFe452f6B101143389Cc')
        const valid = await this.luxChain.isCompany('0xd2AbAC814219E6d9128ffFe452f6B101143389Cc')
        assert.equal(valid, true)
    })

    it('Remove company working correctly', async () => {
        await this.luxChain.addCompany('0xd2AbAC814219E6d9128ffFe452f6B101143389Cc')
        const valid = await this.luxChain.isCompany('0xd2AbAC814219E6d9128ffFe452f6B101143389Cc')
        assert.equal(valid, true)
        //remove company
        await this.luxChain.removeCompany('0xd2AbAC814219E6d9128ffFe452f6B101143389Cc')
        const validRe = await this.luxChain.isCompany('0xd2AbAC814219E6d9128ffFe452f6B101143389Cc')
        assert.equal(validRe, false)
    })

    // it('Non-admin cannot add asset to system', async () => {
    //     var owner = accounts[3];
    //     var assetNumber = "1234";
    //     let price = 1000
    //     try {
    //         await this.bikeChain.addBike(assetNumber, {from: owner, value: price});
    //     } catch (error) {
    //         Error = error;
    //     }
    // })

    it('Admin can add asset to system', async () => {

        var owner = accounts[0];
        var assetNumber = "1234";
        let price = 1000

        await this.luxChain.changeAdminSwitch(true)
        const isAdmin = await this.luxChain.getAdminSwitch()
        console.log(accounts[0])
        assert.equal(isAdmin, true)

        await this.luxChain.addAsset(assetNumber, {from: owner, value: price});

        const item = await this.luxChain.getAsset("1234")
        console.log("Asset Information")
        console.log(item)
        assert.equal(item[0], owner, "Owners not equal");
        assert.notEqual(item[0], "0x0", "Owners not equal");
    })
});
