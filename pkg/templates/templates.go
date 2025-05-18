package templates

import (
	"bytes"
	"html/template"
)

// CompileTemplateFromMap compiles the given HTML template string with the provided data map
func CompileTemplateFromMap(tmplt string, configMap interface{}) (string, error) {
	out := new(bytes.Buffer)
	t, err := template.New("compiled_template").Parse(tmplt)
	if err != nil {
		return "", err
	}
	if err := t.Execute(out, configMap); err != nil {
		return "", err
	}
	return out.String(), nil
}
