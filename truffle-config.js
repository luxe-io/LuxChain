module.exports = {
    // your existing config goes here
    // don't forget to put comma on the last element before proceeding to next line

    compilers: {
        solc: {
            version: "^0.4.17"
        }
    },
    networks: {
        testrpc:{
            host: "localhost",
            port: 7545,
            network_id: "5777"
        }
    }
}