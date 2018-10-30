package testflight_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gbytes"
)
// Test cases:
//
// - when no flag is passed; shows builds from exposed pipelines
// - when team flag is passed; shows builds only for the your current team
// - when --filter-team flag is passed:
// - when you specify a team you don't have access to


// Later
// add tests for the --since --until



// - when no flag is passed; shows builds from exposed pipelines
// - set 2 pipelines, 1 is exposed and one is not.
// - trigger a single build for the 2 pipelines.
// expect fly builds to return only the build for the exposed pipeline.

var _ = FDescribe("fly builds command", func() {
	var (
		testflightHiddenPipeline = "pipeline1"
		testflightExposedPipeline = "pipeline2"
		mainExposedPipeline = "pipeline3"
		mainHiddenPipeline = "pipeline4"
	)

	BeforeEach(func() {
		<-(spawnFlyLogin("-n", "testflight").Exited)

		// hidden pipeline in own team
		pipelineName = testflightHiddenPipeline
		setAndUnpausePipeline("fixtures/hooks.yml")
		fly("trigger-job", "-j", inPipeline("some-passing-job"), "-w")

		// exposed pipeline in own team
		pipelineName = testflightExposedPipeline
		By("Setting pipeline" + pipelineName)
		setAndUnpausePipeline("fixtures/hooks.yml")
		fly("expose-pipeline", "-p", pipelineName)
		fly("trigger-job", "-j", inPipeline("some-passing-job"), "-w")
	})


	BeforeEach(func() {
		<-(spawnFlyLogin("-n", "main").Exited)

		// hidden pipeline in other team
		pipelineName = mainHiddenPipeline
		setAndUnpausePipeline("fixtures/hooks.yml")
		fly("trigger-job", "-j", inPipeline("some-passing-job"), "-w")

		// exposed pipeline in other team
		pipelineName = mainExposedPipeline
		setAndUnpausePipeline("fixtures/hooks.yml")
		fly("trigger-job", "-j", inPipeline("some-passing-job"), "-w")
		fly("expose-pipeline", "-p", pipelineName)
	})

	AfterEach(func () {
		var pipelinesToDestroy = []string{
			testflightHiddenPipeline ,
			testflightExposedPipeline,
			mainExposedPipeline 	,
			mainHiddenPipeline 		,
		};

		<-(spawnFlyLogin("-t", "main").Exited)

		for _, pipeline := range pipelinesToDestroy {
			fly("destroy-pipeline", "-n", "-p", pipeline)
		}
	})

	Context("when no flags passed", func () {
		Context("being logged in as main", func () {
			BeforeEach(func () {
				<-(spawnFlyLogin("-n", "main").Exited)
			})
		})

		Context("being logged in as another team", func () {
			// TODO - create the team first
			BeforeEach(func () {
				<-(spawnFlyLogin("-n", "testflight-another").Exited)
			})
		})

		Context("being logged into custom team", func () {
			JustBeforeEach(func () {
				<-(spawnFlyLogin("-n", "testflight").Exited)
			})

			It("displays the right info", func() {
				sess := spawnFly("builds")
				<-sess.Exited
				Expect(sess.ExitCode()).To(Equal(0))
				Expect(sess).To(gbytes.Say(testflightExposedPipeline))
				Expect(sess).To(gbytes.Say(testflightHiddenPipeline))
			})

			It("doesn't show builds from non-exposed", func () {
				sess := spawnFly("builds", "--team")
				<-sess.Exited
				Expect(sess.ExitCode()).To(Equal(0))
				Expect(sess).NotTo(gbytes.Say(mainHiddenPipeline))
			})
		})

	})
	Context("when specifying values for team flag", func () {
		BeforeEach(func () {
			<-(spawnFlyLogin("-n", "main").Exited)
		})

		FIt("retrieves only builds for the teams specified", func () {
			sess := spawnFly("builds", "--team=testflight")
			<-sess.Exited
			Expect(sess.ExitCode()).To(Equal(0))
			Expect(sess).To(gbytes.Say(testflightExposedPipeline))
			Expect(sess).To(gbytes.Say("testflight"), "shows the team name")
			Expect(sess).NotTo(gbytes.Say(mainExposedPipeline))
		})
	})
})
