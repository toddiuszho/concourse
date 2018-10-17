package atc

import "fmt"

type Plan struct {
	ID       PlanID `json:"id"`
	Attempts []int  `json:"attempts,omitempty"`

	Aggregate *AggregatePlan `json:"aggregate,omitempty"`
	Do        *DoPlan        `json:"do,omitempty"`
	Get       *GetPlan       `json:"get,omitempty"`
	Put       *PutPlan       `json:"put,omitempty"`
	Task      *TaskPlan      `json:"task,omitempty"`
	OnAbort   *OnAbortPlan   `json:"on_abort,ommitempty"`
	Ensure    *EnsurePlan    `json:"ensure,omitempty"`
	OnSuccess *OnSuccessPlan `json:"on_success,omitempty"`
	OnFailure *OnFailurePlan `json:"on_failure,omitempty"`
	Try       *TryPlan       `json:"try,omitempty"`
	Timeout   *TimeoutPlan   `json:"timeout,omitempty"`
	Retry     *RetryPlan     `json:"retry,omitempty"`

	// used for 'fly execute'
	UserArtifact   *UserArtifactPlan   `json:"user_artifact,omitempty"`
	ArtifactOutput *ArtifactOutputPlan `json:"artifact_output,omitempty"`

	// deprecated, kept for backwards compatibility to be able to show old builds
	DependentGet *DependentGetPlan `json:"dependent_get,omitempty"`
}

type PlanID string

type UserArtifactPlan struct {
	Name string `json:"name"`
}

type ArtifactOutputPlan struct {
	Name string `json:"name"`
}

type OnAbortPlan struct {
	Step Plan `json:"step"`
	Next Plan `json:"on_abort"`
}

type OnFailurePlan struct {
	Step Plan `json:"step"`
	Next Plan `json:"on_failure"`
}

type EnsurePlan struct {
	Step Plan `json:"step"`
	Next Plan `json:"ensure"`
}

type OnSuccessPlan struct {
	Step Plan `json:"step"`
	Next Plan `json:"on_success"`
}

type TimeoutPlan struct {
	Step     Plan   `json:"step"`
	Duration string `json:"duration"`
}

type TryPlan struct {
	Step Plan `json:"step"`
}

type AggregatePlan []Plan

type DoPlan []Plan

type GetPlan struct {
	Type        string   `json:"type"`
	Name        string   `json:"name,omitempty"`
	Resource    string   `json:"resource"`
	Source      Source   `json:"source"`
	Params      Params   `json:"params,omitempty"`
	Version     *Version `json:"version,omitempty"`
	VersionFrom *PlanID  `json:"version_from,omitempty"`
	Tags        Tags     `json:"tags,omitempty"`

	VersionedResourceTypes VersionedResourceTypes `json:"resource_types,omitempty"`
}

type PutPlan struct {
	Type     string   `json:"type"`
	Name     string   `json:"name,omitempty"`
	Resource string   `json:"resource"`
	Source   Source   `json:"source"`
	Params   Params   `json:"params,omitempty"`
	Tags     Tags     `json:"tags,omitempty"`
	Inputs   []string `json:"inputs,omitempty"`

	VersionedResourceTypes VersionedResourceTypes `json:"resource_types,omitempty"`
}

type TaskPlan struct {
	Name string `json:"name,omitempty"`

	Privileged bool `json:"privileged"`
	Tags       Tags `json:"tags,omitempty"`

	ConfigPath string      `json:"config_path,omitempty"`
	Config     *TaskConfig `json:"config,omitempty"`

	Params            Params            `json:"params,omitempty"`
	InputMapping      map[string]string `json:"input_mapping,omitempty"`
	OutputMapping     map[string]string `json:"output_mapping,omitempty"`
	ImageArtifactName string            `json:"image,omitempty"`

	VersionedResourceTypes VersionedResourceTypes `json:"resource_types,omitempty"`
}

type RetryPlan []Plan

type DependentGetPlan struct {
	Type     string `json:"type"`
	Name     string `json:"name,omitempty"`
	Resource string `json:"resource"`
}

type PutInputNotFoundError struct {
	Input string
}

func (e PutInputNotFoundError) Error() string {
	return fmt.Sprintf("put input not found within artifacts: %s", e.Input)
}

type PutInputs interface {
	Inputs(worker.ArtifactRepository) ([]worker.InputSource, error)
}

type allInputs struct{}

func NewAllInputs() PutInputs {
	return &allInputs{}
}

func (i allInputs) IncludeInput(artifact string) bool {
	return true
}

type specificInputs struct {
	inputs []string
}

func (i specificInputs) IncludeInput(artifact string) bool {
	putInputs := []string{}
	for _, i := range i.inputs {
		bad := false

		for _, a := range artifacts {
			if i == a {
				putInputs = append(putInputs, i)
				bad = true
				break
			}
		}

		if bad == false {
			return nil, PutInputNotFoundError{Input: i}
		}
	}

	return putInputs, nil
}
