<script>
    import MetaMaskSDK from "@metamask/sdk";
    import { onMount } from "svelte";
    import { BrowserProvider, Contract } from "ethers";
    import spinning from "$lib/assets/spinning.gif";

    import Modal from "./Modal.svelte";
    import { ConsoleLogger } from "@lens-protocol/react-web";

    // This is already deployed countract, so count could be
    // already greater than zero.
    const contAddr = "0xB792F4AE5351917d18639d1E132e7F585e579E07";
    const sepoliaChainId = "0xAA36A7"; // Sepolia Chain ID in hexadecimal (11155111 in decimal)

    // To show spinning logo

    const abi = [
        "function count() public view returns(int256)",
        "function plus() public",
        "function minus() public",
    ];

    let sdk = {};
    let contract = $state({});
    let tx = $state({});
    let count = $state(0);
    let signer = $state({});
    let provider = $state(null);
    let connectError = $state("");
    let buttonLabel = $state("connect");
    let showModal = $state(false);
    let showLoading = $state(false);

    onMount(() => {
        sdk = new MetaMaskSDK({
            dappMetadata: {
                name: "Metamask Demo using Svelte",
                url: window.location.href,
            },
        });
    });

    const walletSwitch = async () => {
        const currentChainId = await ethereum.request({
            method: "eth_chainId",
        });
        if (currentChainId !== sepoliaChainId) {
            try {
                await ethereum.request({
                    method: "wallet_switchEthereumChain",
                    params: [{ chainId: sepoliaChainId }],
                });
            } catch (switchError) {
                console.error(
                    "Failed to switch to Sepolia network:",
                    switchError,
                );
                if (switchError.code === 4902) {
                    console.error(
                        "Sepolia network not found in user's MetaMask.",
                    );
                }
            }
        }
    };

    const connect = async () => {
        try {
            connectError = " ";
            buttonLabel = "Connecting...";
            const ethereum = sdk.getProvider();
            await ethereum.request({ method: "eth_requestAccounts" });
            provider = new BrowserProvider(ethereum);
            signer = await provider.getSigner();
            contract = new Contract(contAddr, abi, signer);

            if (contract) {
                buttonLabel = "connected";
            }

            // Since the contract has been deployed to sepolia network.
            await walletSwitch();

            count = await contract.count();

            // Track account changes.
            ethereum.on("accountsChanged", handleAccountsChanged);
        } catch (e) {
            connectError = "Error connection, refresh page and try again";
            buttonLabel = "Connect";
        }
    };

    const handleAccountsChanged = async (accounts) => {
        provider = new BrowserProvider(ethereum);
        signer = await provider.getSigner();
        contract = new Contract(contAddr, abi, signer);
    };

    const plusOrMinus = async (instruct) => {
        const contLength = Object.keys(contract).length;

        if (!contLength) {
            await connect();
            return;
        }

        await walletSwitch();

        try {
            showModal = true;
            if (instruct == "plus") {
                tx = await contract.plus();
            } else {
                tx = await contract.minus();
            }
        } catch (error) {
            showModal = false;
            return;
        }

        showModal = false;

        showLoading = true;

        await tx.wait();

        showLoading = false;

        count = await contract.count();
        console.log(count);
    };
</script>

<div id="app" class="center-container">
    {#if connectError}
        <p>{connectError}</p>
    {/if}

    <button onclick={connect}>{buttonLabel}</button>
    <p>Count: {count}</p>

    <div class="button-container">
        <button onclick={() => plusOrMinus("plus")}>+</button>
        <button onclick={() => plusOrMinus("minus")}>-</button>
    </div>

    {#if showModal}
        <Modal />
    {/if}

    {#if showLoading}
        <div class="loading-container">
            <img src={spinning} alt="Loading.." class="spinner" />
        </div>
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

    .spinner {
        width: 50px;
        height: 50px;
        margin-bottom: 15px;
    }

    .loading-container {
        margin-top: 10px;
    }
</style>
