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
import { isRef, reactive, ref as allocRef } from "vue";

function nil() {}

function allocateStateCB(map) {
    if (typeof map === "function") {
        return map;
    }

    return function (service) {
        if (map.__all__) {
            map.__all__(service);
        }
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
        if (service._contextRefs) {
            service._contextRefs.forEach(({ key, ref }) => {
                if (isRef(ref)) {
                    const rb = ref;
                    rb.value = ctx[key];
                } else {
                    Object.assign(ref, ctx[key]);
                }
            });
        }
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
    let _ref;
    if (
        typeof service.context[key] === typeof [] ||
        typeof service.context[key] === typeof {}
    ) {
        const s = service;
        _ref = reactive(service.context[key]);
        s.context[key] = _ref;
    } else {
        _ref = allocRef(service.context[key]);
    }
    const ctxRef = {
        key: key,
        ref: _ref
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
