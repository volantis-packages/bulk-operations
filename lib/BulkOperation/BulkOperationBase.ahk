class BulkOperationBase {
    container := ""
    results := Map()
    status := Map()
    owner := ""
    parent := ""
    running := false
    completed := false
    successCount := 0
    failedCount := 0
    allowCancel := false
    useProgress := true
    progress := ""
    progressTitle := "Bulk Operation"
    progressText := "Please stand by..."
    progressInitialDetailText := "Initializing..."
    progressRangeEnd := 100
    progressInitialValue := 0
    shouldNotify := false
    successMessage := "Processed {n} item(s) successfully."
    failedMessage := "There were {n} item(s) that failed."

    __New(container, owner := "") {
        InvalidParameterException.CheckTypes("BulkOperationBase", "container", container, "ContainerBase")
        this.container := container
        this.owner := owner
    }

    Run() {
        if (this.completed) {
            return (this.successCount > 0 && this.failedCount == 0)
        }

        if (this.running) {
            return false
        }

        if (!this.VerifyRequirements()) {
            return false
        }

        if (this.container.Has("logger")) {
            this.container["logger"].Debug(Type(this) . ": Starting bulk operation...")
        }

        this.running := true
        this.ShowProgressWindow()
        this.RunAction()
        this.CloseProgressWindow()
        this.Notify()
        this.running := false
        this.completed := true
        this.LogResults()
        return (this.failedCount == 0)
    }

    LogResults() {
        if (this.container.Has("logger")) {
            this.container["logger"].Info(Type(this) . " Results: " . this.GetResultMessage())
        }
    }

    VerifyRequirements() {
        return true
    }

    GetResults() {
        return this.results
    }

    GetStatus(key := "") {
        if (key == "") {
            return this.status
        }

        if (!this.status.Has(key)) {
            this.status[key] := BasicOpStatus()
        }

        return this.status[key]
    }

    ShowProgressWindow() {
        if (this.useProgress && this.this.container.Has("manager.theme")) {
            ; Ensure that the GUI and theme managers have loaded
            this.container["manager.theme"]
            this.container["manager.gui"]

            if (!IsObject(this.progress)) {
                ownerOrParent := this.owner

                if (this.parent) {
                    ownerOrParent := this.parent
                }

                this.progress := this.container["manager.gui"].OpenWindow(Map(
                    "type", "ProgressIndicator",
                    "title", this.progressTitle,
                    "text", this.progressText,
                    "ownerOrParent", ownerOrParent,
                    "child", !!(this.parent),
                    "allowCancel", this.allowCancel,
                    "rangeStop", this.progressRangeEnd,
                    "startingPosition", this.progressInitialValue,
                    "detailText", this.progressInitialDetailText,
                    "unique", true
                ))
            } else {
                this.progress.Show()
            }
        }
    }

    CloseProgressWindow() {
        if (this.useProgress && IsObject(this.progress)) {
            this.progress.Finish()
        }
    }

    Notify() {
        if (this.shouldNotify && this.container.Has("notifier")) {
            this.container["notifier"].Info(this.GetResultMessage())
        }
    }

    GetResultMessage() {
        message := StrReplace(this.successMessage, "{n}", this.successCount)

        if (this.failedCount > 0) {
            message .= "`n" . StrReplace(this.failedMessage, "{n}", this.failedCount)
        }

        return message
    }

    RunAction() {
        throw MethodNotImplementedException("BulkOperationBase", "RunAction")
    }

    StartItem(key, statusText := "") {
        statusObj := this.GetStatus(key)
        statusObj.Start()

        if (this.useProgress) {
            this.progress.IncrementValue(1, statusText)
        }
    }

    FinishItem(key, success := true, statusText := "", err := "", errCode := "") {
        statusObj := this.GetStatus(key)
        statusObj.Finish(success, err, errCode)

        if (success) {
            this.successCount++
        } else {
            this.failedCount++
        }

        if (this.useProgress && statusText) {
            this.progress.SetDetailText(statusText)
        }
    }
}
