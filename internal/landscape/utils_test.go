package landscape

import "testing"

func TestCheckForTfVars(t *testing.T) {
	testCases := []struct {
		desc        string
		varFileName string
		version     string
		fail        bool
	}{
		{
			desc: "valid file",
		},
	}
	for _, tC := range testCases {
		t.Run(tC.desc, func(t *testing.T) {

		})
	}
}
