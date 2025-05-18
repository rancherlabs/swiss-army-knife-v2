package templates

// Template constants
const (
	// ID for the request info section
	reqInfoID = "reqInfo"

	// HTML head section with styles and metadata
	webHead = `<html>
  <head>
    <title>Swiss-Army-Knife</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
      body {
        background-color: white;
        text-align: center;
        padding: 50px;
        font-family: "Open Sans", "Helvetica Neue", Helvetica, Arial, sans-serif;
      }
      button {
        background-color: #0075a8;
        border: none;
        color: white;
        padding: 15px 32px;
        text-align: center;
        text-decoration: none;
        display: inline-block;
        font-size: 16px;
        cursor: pointer;
      }
      #logo {
        margin-bottom: 40px;
      }
      table {
        margin: 20px auto;
        border-collapse: collapse;
        width: 80%;
      }
      th, td {
        border: 1px solid #ddd;
        padding: 8px;
        text-align: left;
      }
      th {
        background-color: #0075a8;
        color: white;
      }
      tr:nth-child(even) {
        background-color: #f2f2f2;
      }
      .social img {
        margin: 5px;
      }
    </style>
  </head>
<body>
  <h2><a style="text-decoration: none;" href="https://github.com/rancherlabs/swiss-army-knife-v2">Swiss-Army-Knife</a></h2>
  <img id="logo" src="rancher-logo.svg" alt="Swiss-Army-Knife logo" width="400">
  <br>
  <table>
    <thead>
      <tr>
        <th>Field</th>
        <th>Value</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>Pod name</td>
        <td>{{.Hostname}}</td>
      </tr>
      <tr>
        <td>Pod IP</td>
        <td>{{.IP}}</td>
      </tr>
      <tr>
        <td>Namespace</td>
        <td>{{.Namespace}}</td>
      </tr>
      <tr>
        <td>Node name</td>
        <td>{{.NodeName}}</td>
      </tr>
      <tr>
        <td>Node IP</td>
        <td>{{.NodeIP}}</td>
      </tr>
    </tbody>
  </table>
  <br>`

	webServices = `{{- $length := len .Services }} 
  {{- if gt $length 0 }}
    <div id='Services'>
      <h3>Kubernetes Services Found: {{$length}}</h3>
      <table>
        <thead>
          <tr>
            <th>Service</th>
            <th>Endpoint</th>
          </tr>
        </thead>
        <tbody>
          {{ range $k, $v := .Services }}
          <tr>
            <td>{{ $k }}</td>
            <td>{{ $v }}</td>
          </tr>
          {{ end }}
        </tbody>
      </table>
    </div>
    <br />
  {{ end }}`

	webDetails = `<button class="button" onclick="toggleRequestInfo()">Show Request Details</button>
  <div id="` + reqInfoID + `" style="display: none;">
    <h3>Request Info</h3>
    <table>
      <thead>
        <tr>
          <th>Header</th>
          <th>Value</th>
        </tr>
      </thead>
      <tbody>
        {{- range $key, $value := .Headers }}
        <tr>
          <td>{{ $key }}</td>
          <td>{{ $value }}</td>
        </tr>
        {{- end }}
      </tbody>
    </table>
  </div>
  <br />`

	webLinks = `<div id='rancherLinks' class="row social">
    <a href="https://rancher.com/docs"><img src="img/favicon.png" alt="Rancher Docs" height="25" width="25"></a>
    <a href="https://slack.rancher.io/"><img src="img/icon-slack.svg" alt="Rancher Slack" height="25" width="25"></a>
    <a href="https://github.com/rancher/rancher"><img src="img/icon-github.svg" alt="Rancher GitHub" height="25" width="25"></a>
    <a href="https://twitter.com/Rancher_Labs"><img src="img/icon-twitter.svg" alt="Rancher Twitter" height="25" width="25"></a>
    <a href="https://www.facebook.com/rancherlabs/"><img src="img/icon-facebook.svg" alt="Rancher Facebook" height="25" width="25"></a>
    <a href="https://www.linkedin.com/groups/6977008/profile"><img src="img/icon-linkedin.svg" alt="Rancher LinkedIn" height="25" width="25"></a>
  </div>
  <br />`

	webTail = `<script>
      function toggleRequestInfo() {
        var element = document.getElementById("` + reqInfoID + `");
        if (element.style.display === "none") {
          element.style.display = "block";
        } else {
          element.style.display = "none";
        }
      }
    </script>
  </body>
</html>`

	HelloWorldTemplate = webHead + `
` + webServices + `
` + webLinks + `
` + webDetails + `
` + webTail
)
