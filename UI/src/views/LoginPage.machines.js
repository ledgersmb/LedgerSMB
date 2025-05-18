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
    testNot,
    testResponseOkFn,
    testResponseStatusFn,
    transitionFormValid,
    transitionFormInvalid
} from "@/machine-helpers";

function submitLogin(ctx) {
    return fetch(
        "login.pl?action=authenticate&company=" + encodeURI(ctx.company.value),
        {
            method: "POST",
            body: JSON.stringify({
                company: ctx.company.value,
                password: ctx.password.value,
                login: ctx.username.value
            }),
            headers: new Headers({
                "X-Requested-With": "XMLHttpRequest",
                "Content-Type": "application/json"
            })
        }
    );
}

function createLoginMachine(initialContext) {
    return interpret(
        createMachine(
            {
                invalid: state(transitionFormValid("input", "ready")),
                ready: state(
                    transitionFormInvalid("input", "invalid"),
                    transition("submit", "submitting")
                ),
                submitting: invoke(
                    submitLogin,
                    transition(
                        "error",
                        "ready",
                        action((ctx, e) => {
                            // eslint-disable-next-line no-alert
                            alert(e.error);
                        })
                    ),
                    transition(
                        "done",
                        "submitted",
                        reduce((ctx, e) => ({ ...ctx, response: e.data }))
                    )
                ),
                submitted: state(
                    immediate(
                        "failed",
                        guard(testResponseStatusFn(401)),
                        action((ctx) => {
                            ctx.errorText.value = ctx.t(
                                "Access denied: Bad username or password"
                            );
                        })
                    ),
                    immediate(
                        "failed",
                        guard(testResponseStatusFn(521)),
                        action((ctx) => {
                            ctx.errorText.value = ctx.t(
                                "Database version mismatch"
                            );
                        })
                    ),
                    immediate(
                        "ready",
                        guard(testNot(testResponseOkFn())),
                        action((ctx) => {
                            // eslint-disable-next-line no-alert
                            alert(ctx.t("Unknown error preventing login"));
                        })
                    ),
                    immediate("parsing")
                ),
                parsing: invoke(
                    (ctx) => ctx.response.json(),
                    transition(
                        "done",
                        "final",
                        action((ctx, e) => {
                            window.location.assign(e.data.target);
                        })
                    ),
                    transition(
                        "error",
                        "error",
                        reduce((ctx, e) => ({ ...ctx, error: e.data }))
                    )
                ),
                failed: state(
                    transitionFormValid("input", "ready"),
                    transitionFormInvalid("input", "invalid")
                ),
                final: state(transition("input", "ready")),
                error: state()
            },
            (initialCtx) => initialCtx
        ),
        () => {},
        initialContext
    );
}

export { createLoginMachine };
