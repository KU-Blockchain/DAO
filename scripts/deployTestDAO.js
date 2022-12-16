 async function main(){   
    // Set the required variables for the DAO contract
    const quorum = 50;
    const majority = 60;
    const proposalReputation = 100;
    const votingReputation = 50;
    const proposalVotingPeriod = 604800; // 1 week in seconds

    // Deploy the DAO contract
    const DAOContract = await new web3.eth.Contract(DAO_ABI)
    .deploy({ data: DAO_BYTECODE, arguments: [quorum, majority, proposalReputation, votingReputation, proposalVotingPeriod] })
    .send({ from: owner, gas: 4000000 });

    console.log(`DAO contract deployed at address: ${DAOContract.options.address}`);

    // Set the address of the DAO contract
    const DAO_ADDRESS = DAOContract.options.address;

    // Deploy the KubixToken contract
    const KubixTokenContract = await new web3.eth.Contract(KubixToken_ABI)
    .deploy({ data: KubixToken_BYTECODE })
    .send({ from: owner, gas: 4000000 });

    console.log(`KubixToken contract deployed at address: ${KubixTokenContract.options.address}`);

    // Set the address of the KubixToken contract
    const KUBIX_TOKEN_ADDRESS = KubixTokenContract.options.address;

    // Initialize the DAO contract and mint the "KUBIX" coin
    await DAOContract.methods.initialize(quorum, majority, proposalReputation, votingReputation, proposalVotingPeriod, KUBIX_TOKEN_ADDRESS).send({ from: owner, gas: 4000000 });
    console.log(`DAO contract initialized and "KUBIX" coin minted`);
 }

 main()
   .then(() => process.exit(0))
   .catch(error => {
     console.error(error);
     process.exit(1);
   });