// Decryptor allows one to decrypt an encrypted configuration
// from concourse using a secret key that was supplied to ATC
// and the nonce generated for the field.
//
// The encrypted value can either be provided via `stdin` (default)
// or through the `value` field.
package main

import (
	"bytes"
	"fmt"
	"io"
	"io/ioutil"
	"os"

	"github.com/concourse/concourse/atc/db/encryption"
	"github.com/concourse/flag"
	"github.com/jessevdk/go-flags"
)

var config struct {
	SecretKey flag.Cipher `short:"s" long:"secret-key" required:"true" description:"secret used to encrypt the values" env:"CONCOURSE_ENCRYPTION_KEY"`
	Nonce     string      `short:"n" long:"nonce" required:"true" description:"secret used to encrypt the values"`
	Value     string      `short:"v" long:"value" default:"-" description:"value to decrypt (use '-' for stdin)"`
}

func main() {
	_, err := flags.Parse(&config)
	if err != nil {
		os.Exit(1)
	}

	var reader io.Reader

	if config.Value == "-" {
		reader = os.Stdin
	} else {
		reader = bytes.NewBufferString(config.Value)
	}

	valueToDecrypt, err := ioutil.ReadAll(reader)
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to read contents to decrypt")
		os.Exit(1)
	}

	decryptedContent, err := encryption.
		NewKey(config.SecretKey).
		Decrypt(string(valueToDecrypt), &config.Nonce)
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to decrypt %s", err)
		os.Exit(1)
	}

	fmt.Println(string(decryptedContent))
}
