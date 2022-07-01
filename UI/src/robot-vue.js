/** @format */

import {
    action,
    createMachine,
    guard,
    immediate,
    interpret as interpretRobot,
    invoke,
    reduce,
    state,
    transition
} from "robot3";
import { reactive, ref as allocRef } from "vue";

function nil() {}

function allocateStateCB(map) {
    if (typeof map === "function") {
        return map;
    }

    return function (service) {
        const s = service.machine.current;
        (map[s] || nil)(service);
    };
}

function allocateOnChange(s, onChange) {
    const cb = allocateStateCB(onChange || nil);
    const sb = s;
    return function (service) {
        cb(service);

        sb.value = service.machine.current;
        const ctx = service.context;
        service._contextRefs.forEach(({ key, ref }) => {
            const rb = ref;
            rb.value = ctx[key];
            // objects and arrays are converted to reactive()s
            // upon assignment to a ref's value attribute. We want
            // the context value to be reactive too, so sync back
            // in case this happened.
            if (ctx[key] !== rb.value) {
                ctx[key] = rb.value;
            }
        });
    };
}

function interpret(machine, onChange, initialContext, event) {
    const s = allocRef("");
    const service = interpretRobot(
        machine,
        allocateOnChange(s, onChange),
        initialContext,
        event
    );
    service._contextRefs = [];
    s.value = service.machine.current;

    return {
        service: service,
        send: service.send,
        state: s
    };
}

function contextRef(service, key) {
    let ref;
    if (
        typeof service.context[key] === typeof [] ||
        typeof service.context[key] === typeof {}
    ) {
        const s = service;
        ref = reactive(service.context[key]);
        s.context[key] = ref;
    } else {
        ref = allocRef(service.context[key]);
    }
    const ctxRef = {
        key: key,
        ref: ref
    };
    service._contextRefs.push(ctxRef);
    return ctxRef.ref;
}

export {
    action,
    contextRef,
    createMachine,
    guard,
    immediate,
    interpret,
    invoke,
    reduce,
    state,
    transition
};
