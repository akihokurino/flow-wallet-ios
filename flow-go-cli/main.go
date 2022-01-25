package main

import (
	"context"
	"crypto/rand"
	"fmt"
	"time"

	"github.com/onflow/flow-go-sdk/templates"

	"github.com/onflow/flow-go-sdk/crypto"

	"github.com/onflow/flow-go-sdk"

	"google.golang.org/grpc"

	"github.com/onflow/flow-go-sdk/client"
)

func main() {
	ctx := context.Background()
	testnet := "127.0.0.1:3569"

	defaultAddress := flow.HexToAddress("f8d6e0586b0a20c7")
	defaultPrivateKey, _ := crypto.DecodePrivateKeyHex(crypto.ECDSA_P256, "94e798c159bcdfc1445087fb587ef589574c3951d7e3e0e0e0dd20c6061bf67c")

	flowCli, _ := client.New(testnet, grpc.WithInsecure())
	block, _ := flowCli.GetLatestBlock(ctx, true)
	defaultAccount, _ := flowCli.GetAccountAtLatestBlock(ctx, defaultAddress)
	
	defaultAccountKey := defaultAccount.Keys[0]
	
	seed := make([]byte, crypto.MinSeedLength)
	_, _ = rand.Read(seed)
	nextPrivateKey, _ := crypto.GeneratePrivateKey(crypto.ECDSA_P256, seed)

	nextAccountKey := flow.NewAccountKey().
		FromPrivateKey(nextPrivateKey).
		SetHashAlgo(crypto.SHA3_256).
		SetWeight(flow.AccountKeyWeightThreshold)

	createAccountTx := templates.CreateAccount([]*flow.AccountKey{nextAccountKey}, nil, defaultAddress)
	createAccountTx.SetProposalKey(
		defaultAddress,
		defaultAccountKey.Index,
		defaultAccountKey.SequenceNumber,
	)
	createAccountTx.SetPayer(defaultAddress)
	createAccountTx.SetReferenceBlockID(block.ID)

	defaultSigner := crypto.NewInMemorySigner(defaultPrivateKey, defaultAccountKey.HashAlgo)
	if err := createAccountTx.SignEnvelope(defaultAddress, defaultAccountKey.Index, defaultSigner); err != nil {
		panic(err)
	}

	if err := flowCli.SendTransaction(ctx, *createAccountTx); err != nil {
		panic(err)
	}

	accountCreationTxRes := WaitForSeal(ctx, flowCli, createAccountTx.ID())
	var nextAddress flow.Address

	for _, event := range accountCreationTxRes.Events {
		if event.Type == flow.EventAccountCreated {
			accountCreatedEvent := flow.AccountCreatedEvent(event)
			nextAddress = accountCreatedEvent.Address()
		}
	}

	fmt.Printf("account created with address:%s, private key: %s", nextAddress.Hex(), nextPrivateKey.String())
}

func WaitForSeal(ctx context.Context, c *client.Client, id flow.Identifier) *flow.TransactionResult {
	result, err := c.GetTransactionResult(ctx, id)
	if err != nil {
		panic(err)
	}

	fmt.Printf("waiting for transaction %s to be sealed...\n", id)

	for result.Status != flow.TransactionStatusSealed {
		time.Sleep(time.Second)
		fmt.Print(".")
		result, err = c.GetTransactionResult(ctx, id)
		if err != nil {
			panic(err)
		}
	}

	fmt.Println()
	fmt.Printf("transaction %s sealed\n", id)
	return result
}
