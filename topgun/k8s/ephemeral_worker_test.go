package k8s_test

import (
	"fmt"
	. "github.com/concourse/concourse/topgun"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"path"
	"strconv"
)

// TODO
// - add paths to the charts git-resource
// - make use of a separated namespace
// - make use of separate values.yml files

// deploy helm chart						DONE
// - using the digest from dev-image		DONE
// - configure only one worker				DONE
// - configure the worker to be ephemeral	DONE

// wait for a worker to be running
// set the pipeline

// delete the worker's pod
// --- poll or `kubctl get pods --watch` until the pod is terminated
// expect that the worker doesn't have any volumes or containers on it:
// - according to fly volumes ++ fly containers
// - on the actual worker

// delete the helm release


func HelmDeploy(releaseName string){
	helmArgs := []string{
		"upgrade",
		"-f",
		path.Join(Environment.ChartDir,"values.yaml"),
		"--install",
		"--force",
		"--set=concourse.web.kubernetes.keepNamespaces=false",
		"--set=concourse.worker.ephemeral=true",
		"--set=image="+Environment.ConcourseImageName,
		"--set=imageDigest="+Environment.ConcourseImageDigest,
		releaseName,
		"--wait",
		Environment.ChartDir,
	}

	Wait(Spawn("helm", helmArgs...))
}


func HelmDestroy(releaseName string){
	helmArgs := []string{
		"delete",
		releaseName,
	}

	Wait(Spawn("helm", helmArgs...))
}

var _ = Describe("Ephemeral workers", func () {
	var fly Fly

	BeforeEach(func(){
		HelmDeploy(fmt.Sprintf("topgun-ephemeral-workers-%d",GinkgoParallelNode()))

		fly = Fly{
			Bin: flyPath,
			Target: "concourse-topgun-k8s-" + strconv.Itoa(GinkgoParallelNode()),
		}
	})

	AfterEach(func() {
		HelmDestroy(fmt.Sprintf("topgun-ephemeral-workers-%d",GinkgoParallelNode()))
	})

	It("Gets properly cleaned when getting removed and then put back on", func () {
		By("Logging in")
		fly.Login("test", "test", "??")

		// prepare fly
		// wait for worker to be there
		// set a pipeline
		// unpause pipeline
		// wait for it to run at least one job
		// delete the worker's pod

		Expect(true).To(Equal(true))
	})
})

