package k8s_test

import (
	"testing"

	"github.com/caarlos0/env"
	. "github.com/concourse/concourse/topgun"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

func TestK8s(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "K8s Suite")
}

var (
	Environment struct {
		ConcourseImageDigest string `env:"CONCOURSE_IMAGE_DIGEST"`
		ConcourseImageName   string `env:"CONCOURSE_IMAGE_NAME,required"`
		ConcourseImageTag    string `env:"CONCOURSE_IMAGE_TAG"`
		ChartDir             string `env:"CHART_DIR,required"`
	}
	flyPath string
)

var _ = SynchronizedBeforeSuite(func() []byte {
	return []byte(BuildBinary())
}, func(data []byte) {
	flyPath = string(data)
})

var _ = BeforeSuite(func() {
	err := env.Parse(&Environment)
	Expect(err).ToNot(HaveOccurred())

	By("Checking if kubectl has a context set")
	Wait(Spawn("kubectl", "config", "current-context"))

	By("Installing tiller")
	Wait(Spawn("helm", "init", "--wait"))
	Wait(Spawn("helm", "dependency", "update", Environment.ChartDir))
})

