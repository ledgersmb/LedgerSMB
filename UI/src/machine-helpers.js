/** @format */

import { guard, transition } from "@/robot-vue";
const registry = require("dijit/registry");

export function testNot(fn) {
    return (...args) => !fn(...args);
}

export function testFormValidFn(formFn = (ctx) => ctx.form.value) {
    return (ctx) =>
        registry
            .findWidgets(formFn(ctx))
            .reduce(
                (acc, w) => acc && (w.disabled || !w.validate || w.validate()),
                true
            );
}

export function testResponseOkFn(responseFn = (ctx) => ctx.response) {
    return (ctx) => responseFn(ctx).ok;
}

export function testResponseStatusFn(
    status,
    responseFn = (ctx) => ctx.response
) {
    return (ctx) => responseFn(ctx).status === status;
}

export function transitionFormValid(event, target) {
    return transition(event, target, guard(testFormValidFn()));
}

export function transitionFormInvalid(event, target) {
    return transition(event, target, guard(testNot(testFormValidFn())));
}

export function progressNotify(fn, progress) {
    return async (ctx) => {
        let dismiss;

        if (progress) {
            let cbp = ctx.notifications[progress];
            if (cbp) {
                cbp(ctx, {
                    dismissReceiver: (d) => {
                        dismiss = d;
                    }
                });
            }
        }
        return fn(ctx).finally(() => {
            if (dismiss) {
                dismiss();
            }
        });
    };
}

export function notify(notification) {
    return (ctx, event) => {
        let cb = ctx.notifications[notification];
        if (cb) {
            cb(ctx, { event });
        }
    };
}
