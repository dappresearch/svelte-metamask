<script>
    import MetaMaskSDK from '@metamask/sdk';
    import { onMount } from 'svelte';
    import { BrowserProvider, Contract } from "ethers";
  
    // This is already deployed countract, so count could be 
    // already greater than zero.
    const contAddr = "0xB792F4AE5351917d18639d1E132e7F585e579E07";
    const sepoliaChainId = "0xAA36A7"; // Sepolia Chain ID in hexadecimal (11155111 in decimal)

    const abi = [
        "function count() public view returns(int256)",
        "function plus() public",
        "function minus() public"
    ];

    let sdk=({});
    let contract = $state({});
    let tx = $state({});
    let count = $state(0);
    let increasePromise = $state(null);
    let decreasePromise = $state(null);
    let signer = $state({});
    let provider = $state(null);
    let connectError = $state('');
    let buttonLabel = $state('connect');
    
    onMount(() => {
        sdk = new MetaMaskSDK({
            dappMetadata: {
                name: "Metamask Demo using Svelte",
                url: window.location.href,
            },
        });   
    });

    const walletSwitch = async () => {
        const currentChainId = await ethereum.request({ method: 'eth_chainId' });
        if (currentChainId !== sepoliaChainId) {
            try {
                await ethereum.request({
                    method: 'wallet_switchEthereumChain',
                    params: [{ chainId: sepoliaChainId }],
                });
            } catch (switchError) {
                console.error("Failed to switch to Sepolia network:", switchError);
                if (switchError.code === 4902) {
                    console.error("Sepolia network not found in user's MetaMask.");
                }
            }
        }
    }

    const connect = async () => {
        try {
            buttonLabel = 'Connecting...'; 
            const ethereum = sdk.getProvider();
            await ethereum.request({ method: 'eth_requestAccounts' });
            provider = new BrowserProvider(ethereum);
            signer = await provider.getSigner();
            contract = new Contract(contAddr, abi, signer);

            if(contract) {
                buttonLabel = 'connected';
            }
            // Since the contract has been deployed to sepolia network.
            await walletSwitch();

            count = await contract.count();

            // Track account changes.
            ethereum.on("accountsChanged", handleAccountsChanged);

        } catch(e) {
            connectError = "Error connection to wallet";
            buttonLabel = 'Connect';
        }
    };

    const handleAccountsChanged = async(accounts) => {
        provider = new BrowserProvider(ethereum);
        signer = await provider.getSigner();
        contract = new Contract(contAddr, abi, signer);
    };

    const increase = async () => {
        if (!contract) {
            await connect();
        }

        await walletSwitch();

        tx = await contract.plus();
        await tx.wait();
        count = await contract.count();
        console.log(count);
    };

    const decrease = async () => {
        if (!contract) {
            await connect();
        }

        await walletSwitch();

        tx = await contract.minus();
        await tx.wait();
        count = await contract.count();
    };
</script>

<div id="app" class="center-container">
    {#if connectError}
        <p>{connectError}</p>
    {/if}

    <button onclick={connect}>{buttonLabel}</button>
    <p>Count: {count}</p>
    
    <div class="button-container">
        <button onclick={() => increasePromise = increase()}>+</button>
        <button onclick={() => decreasePromise = decrease()}>-</button>
    </div>


    {#if increasePromise && contract}
        {#await increasePromise}
            <p>Waiting for signature and transaction hash</p>
        {:then}
            <p>Transaction Hash: {tx.hash}</p>
        {:catch error}
            <p style="color: red">Problem connecting</p>
        {/await}
    {/if}

 
    {#if decreasePromise && contract}
        {#await decreasePromise}
            <p>Waiting for signature and transaction hash</p>
        {:then}
            <p>Transaction Hash: {tx.hash}</p>
        {:catch error}
            <p style="color: red">Problem connecting</p>
        {/await}
    {/if}
</div>

<style>
    
    .center-container {
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        min-height: 100vh;
        text-align: center;
    }

    .button-container {
        margin-top: 20px;
    }

    button {
        margin: 0 10px;
        padding: 10px 20px;
        font-size: 16px;
        cursor: pointer;
    }

    p {
        font-size: 18px;
    }
</style>
