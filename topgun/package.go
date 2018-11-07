package topgun

import (
	"encoding/json"
	"os/exec"
	"strings"
	"time"

	"github.com/onsi/gomega/gexec"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

type Fly struct {
	Bin    string
	Target string
}

type Worker struct {
	Name string `json:"name""`
	State string `json:"state"`
}

func (f *Fly) Login(user, password, endpoint string) {
	Eventually(func() *gexec.Session {
		return f.Spawn(
			"login",
			"-c", endpoint,
			"-u", user,
			"-p", password,
		).Wait()
	}, 2*time.Minute).
		Should(gexec.Exit(0), "Fly should have been able to log in")
}

func (f *Fly) Spawn(argv ...string) *gexec.Session {
	return Spawn(f.Bin, append([]string{"--verbose", "-t", f.Target}, argv...)...)
}

func (f *Fly) GetWorkers() []Worker {
	var workers = []Worker{}

	sess := f.Spawn("workers", "--json")
	<-sess.Exited
	Expect(sess.ExitCode()).To(BeZero())

	err := json.Unmarshal(sess.Out.Contents(), &workers)
	Expect(err).ToNot(HaveOccurred())

	return workers
}

func Wait(session *gexec.Session) {
	<-session.Exited
	Expect(session.ExitCode()).To(Equal(0))
}

func Spawn(argc string, argv ...string) *gexec.Session {
	By("running: " + argc + " " + strings.Join(argv, " "))

	cmd := exec.Command(argc, argv...)
	session, err := gexec.Start(cmd, GinkgoWriter, GinkgoWriter)
	Expect(err).ToNot(HaveOccurred())
	return session
}

func BuildBinary() string {
	flyBinPath, err := gexec.Build("github.com/concourse/concourse/fly")
	Expect(err).ToNot(HaveOccurred())

	return flyBinPath
}
