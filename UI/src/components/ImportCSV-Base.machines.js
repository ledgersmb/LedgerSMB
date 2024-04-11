/** @format */

import {
    action,
    createMachine,
    immediate,
    interpret,
    invoke,
    guard,
    reduce,
    state,
    transition
} from "@/robot-vue";
import {
    progressNotify,
    notify,
    testNot,
    testResponseOkFn,
    transitionFormValid,
    transitionFormInvalid
} from "@/machine-helpers.js";

function submitUpload(ctx) {
    let data = new FormData(ctx.form.value);
    data.append("action", "run_import");

    return fetch("import_csv.pl", {
        method: "POST",
        body: data,
        headers: new Headers({
            "X-Requested-With": "XMLHttpRequest"
        })
    });
}

function createImportMachine(initialContext) {
    return interpret(
        createMachine(
            {
                invalid: state(transitionFormValid("input", "ready")),
                ready: state(
                    transitionFormInvalid("input", "invalid"),
                    transition("submit", "submitting")
                ),
                submitting: invoke(
                    progressNotify(submitUpload),
                    transition("error", "ready", action(notify("submitError"))),
                    transition(
                        "done",
                        "submitted",
                        reduce((ctx, e) => ({ ...ctx, response: e.data }))
                    )
                ),
                submitted: state(immediate("parsing")),
                parsing: invoke(
                    (ctx) => ctx.response.json(),
                    transition(
                        "done",
                        "failed",
                        guard(testNot(testResponseOkFn())),
                        action(notify("processingError"))
                    ),
                    transition("done", "final", action(notify("success"))),
                    transition(
                        "error",
                        "error",
                        reduce(notify("responseError"))
                    )
                ),
                failed: state(
                    transitionFormValid("input", "ready"),
                    transitionFormInvalid("input", "invalid")
                ),
                final: state(),
                error: state()
            },
            (initialCtx) => initialCtx
        ),
        () => {},
        initialContext
    );
}

export { createImportMachine };
