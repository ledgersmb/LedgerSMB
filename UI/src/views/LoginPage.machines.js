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
const registry = require("dijit/registry");

const not = (fn) => (
    (...args) => !fn(...args)
);
const formValid =
      (ctx) => registry.findWidgets(ctx.form.value).reduce(
            (acc, w) => (acc && (w.disabled || !w.validate || w.validate())),
            true
        );
const okResponse = (ctx) => ctx.response.ok;
const responseStatus = (status) => (
    (ctx) => (ctx.response.status === status)
);


function submitLogin(ctx) {
    return fetch("login.pl?action=authenticate&company=" + encodeURI(ctx.company.value), {
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
    });
}

const transitionToInvalid =
    (event) => transition(event, 'invalid',
                                guard(not(formValid)));
const transitionToReady =
    (event) => transition(event, 'ready',
                                guard(formValid));


function createLoginMachine(initialContext) {
    return interpret(
        createMachine({
            invalid: state(
                transitionToReady('input'),
            ),
            ready: state(
                transitionToInvalid('input'),
                transition('submit', 'submitting'),
            ),
            submitting: invoke(
                submitLogin,
                transition(
                    'error', 'ready',
                    action((ctx, e) => { alert(e.error); }) // eslint-disable-line no-alert
                ),
                transition(
                    'done', 'submitted',
                    reduce((ctx, e) => ({ ...ctx, response: e.data})),
                ),
            ),
            submitted: state(
                immediate(
                    'failed',
                    guard(responseStatus(401)),
                    action((ctx) => {
                        ctx.errorText.value = ctx.t("Access denied: Bad username or password");
                    }),
                ),
                immediate(
                    'failed',
                    guard(responseStatus(521)),
                    action((ctx) => {
                        ctx.errorText.value = ctx.t("Database version mismatch");
                    }),
                ),
                immediate(
                    'ready',
                    guard(not(okResponse)),
                    action((ctx) => {
                        alert(ctx.t("Unknown error preventing login")); // eslint-disable-line no-alert
                    }),
                ),
                immediate('parsing'),
            ),
            parsing: invoke(
                ctx => ctx.response.json(),
                transition(
                    'done', 'final',
                    action((ctx, e) => { window.location.href = e.data.target; }),
                ),
                transition(
                    'error', 'error',
                    reduce((ctx, e) => ({ ...ctx, error: e.data }))),
            ),
            failed: state(
                transitionToReady('input'),
                transitionToInvalid('input'),
            ),
            final: state(),
            error: state(),
        }, initialCtx => initialCtx),
        () => {},
        initialContext);
}

export { createLoginMachine };
