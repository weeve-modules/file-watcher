package main

import (
	"encoding/json"
	"fmt"
	"syscall"

	"bytes"
	"net/http"
	"os"
	"os/signal"
	"time"

	"github.com/fsnotify/fsnotify"
	"github.com/jessevdk/go-flags"
	log "github.com/sirupsen/logrus"
)

type Data struct {
	FileName string
	OpCode   int
	OpName   string
	Time     int64
}

type Params struct {
	Verbose []bool `long:"verbose" short:"v" description:"Show verbose debug information"`
	Develop []bool `long:"develop" short:"d" description:"Disable egress"`
	Folder  string `long:"folder" short:"f" description:"Folder to watch" required:"true"`
}

var opt Params
var parser = flags.NewParser(&opt, flags.Default)

func init() {
	log.SetFormatter(&log.TextFormatter{})
	log.SetOutput(os.Stdout)

	log.SetLevel(log.DebugLevel)
	log.Info("Started logging")

}

// Simple utility to assert and return an environment variable
func GetEnvAsserted(envVarName string) string {
	var thisEnvVar = os.Getenv(envVarName)
	if len(thisEnvVar) == 0 {
		log.Fatal(envVarName, " was not found in the current environment")
	}
	return thisEnvVar
}

func main() {
	c := make(chan os.Signal)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-c
		log.Info("Stopped via CTRL-C")
		os.Exit(1)
	}()
	// Parse the CLI options
	if _, err := parser.Parse(); err != nil {
		log.Error("Error on command line parser ", err)
		os.Exit(1)
	}
	var moduleName = GetEnvAsserted("MODULE_NAME")
	var egressUrl = GetEnvAsserted("EGRESS_URL")
	log.Info("This module name: ", moduleName)
	log.Info("Egress URL: ", egressUrl)
	_, _ = moduleName, egressUrl

	log.Info("Folder to watch: ", opt.Folder)

	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		log.Fatal(err)
	}
	defer watcher.Close()

	done := make(chan bool)
	go func() {
		for {
			select {
			case event, ok := <-watcher.Events:
				if !ok {
					return
				}
				// Build the data item
				var thisData Data
				thisData.FileName = event.Name
				thisData.OpCode = int(event.Op)
				thisData.OpName = event.Op.String()
				thisData.Time = time.Now().Unix()

				// Convert to JSON object
				data, err := json.Marshal(thisData)
				if err != nil {
					fmt.Println(err)
				}
				log.Debug(fmt.Sprintf("Event JSON Data: %s\n", string(data)))
				postJson(data, egressUrl)

			case err, ok := <-watcher.Errors:
				if !ok {
					return
				}
				log.Error("error:", err)
			}
		}
	}()

	err = watcher.Add(opt.Folder)
	if err != nil {
		log.Fatal(err)
	}
	<-done

}

func postJson(jsonData []byte, URL string) {
	log.Debug("POSTing to ", URL)
	resp, err := http.Post(URL, "application/json; charset=utf-8", bytes.NewBuffer(jsonData))
	if err != nil {
		log.Error(err)
		return
	}
	defer resp.Body.Close()

	log.Debug("POST response: ", resp.StatusCode)
}
