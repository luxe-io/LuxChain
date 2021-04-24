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

    it('Admin can add asset to system', async () => {
        console.log("Admin can add asset to system")
        console.log("-------------*****************-------------")
        console.log("")

        var owner = accounts[0];
        var assetNumber = "1234";
        let price = 1000

        await this.luxChain.changeAdminSwitch(true)
        const isAdmin = await this.luxChain.getAdminSwitch()
        console.log("Current Account:" + owner)
        assert.equal(isAdmin, true)

        await this.luxChain.addAsset(assetNumber, {from: owner, value: price});

        const item = await this.luxChain.getAsset("1234")
        console.log("Asset Information")
        console.log(item)
        assert.equal(item[0], owner, "Owners not equal");
        assert.notEqual(item[0], "0x0", "Owners not equal");
    })

    it('Cannot add a duplicate asset for the assetNumber that exist on the blockchain', async () => {
        console.log("-------------*****************-------------")
        console.log("")

        const item = await this.luxChain.getAsset("1234")
        console.log("Asset Information")
        console.log(item)

        var owner = accounts[0];
        var assetNumber = "1234";
        let price = 1000

        await this.luxChain.changeAdminSwitch(true)
        const isAdmin = await this.luxChain.getAdminSwitch()
        console.log("Current Account:" + owner)
        assert.equal(isAdmin, true)

        try {
            await this.luxChain.addAsset(assetNumber, {from: owner, value: price});
        }
        catch (err){
            assert.isAbove(err.message.search('VM Exception while processing transaction: revert'), -1, 'Error: VM Exception while processing transaction: revert');
        }
    })

    it('Transfer ownership of Asset to another user', async () => {
        console.log("Transfer ownership of Asset to another user")
        console.log("-------------*****************-------------")
        console.log("")
        var owner = accounts[0];
        var newOwner = accounts[1];
        var assetNumber = "1234";
        let price = 1000
        console.log("Current Account:" + owner)
        console.log("New Account:" + newOwner)
        console.log("")
        await this.luxChain.changeAdminSwitch(true)
        const isAdmin = await this.luxChain.getAdminSwitch()
        let item = await this.luxChain.getAsset("1234")
        console.log("Asset Information Before Transfer")
        console.log(item)

        await this.luxChain.transferOwner(assetNumber, newOwner);
        console.log("---------------------------------")
        item = await this.luxChain.getAsset("1234")
        console.log("Asset Information After Transfer")
        console.log(item)
        assert.equal(item[0], newOwner, "Owners not equal");
        assert.notEqual(item[0], "0x0", "Owners not equal");
    })

});
