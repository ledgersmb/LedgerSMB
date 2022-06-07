/** @format */

import {
    action,
    createMachine,
    guard,
    interpret as interpretRobot,
    invoke,
    reduce,
    state,
    transition
} from "robot3";
import { ref } from "vue";

function nil() {}

function allocateOnChange(state, onChange) {
    onChange = onChange || nil;
    return function(service) {
        onChange(service);

        state.value = service.machine.current;
        let ctx = service.context;
        service._contextRefs.forEach(
            ({key, ref}) => {
                ref.value = ctx[key];
            });
    };
}

function interpret(machine, onChange, initialContext, event) {
    let state = ref("");
    let service = interpretRobot(
        machine,
        allocateOnChange(state, onChange),
        initialContext,
        event);
    service._contextRefs = [];
    state.value = service.machine.current;

    return {
        service,
        send: service.send,
        state
    };
}

function contextRef(service, key) {
    let ctxRef = {
        key: key,
        ref: ref(service.context[key])
    };
    service._contextRefs.push(ctxRef);
    return ctxRef.ref;
}


export {
    action,
    contextRef,
    createMachine,
    guard,
    interpret,
    invoke,
    reduce,
    state,
    transition
};
