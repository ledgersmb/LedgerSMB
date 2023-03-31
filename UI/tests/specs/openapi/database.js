/* eslint-disable camelcase */
// Import test packages
import { spawnSync } from "child_process";

// Access to the database test user

const pg_user = process.env.PGUSER ? process.env.PGUSER : "postgres";
const pg_pwd = process.env.PGPASSWORD ? process.env.PGPASSWORD : "abc";
const pg_host = process.env.PGHOST ? process.env.PGHOST : "localhost";

export function create_database(username, password, company) {
    let cmd = spawnSync(
        "./bin/ledgersmb-admin",
        ["create", `${pg_user}@${pg_host}/${company}#xyz`],
        {
            cwd: process.env.PWD + "/.."
        }
    );
    if (cmd.status !== 0) {
        throw new Error(cmd.stderr.toString());
    }
    if (cmd.error) {
        if (typeof cmd.error === "string") {
            cmd.error = new Error(cmd.error);
        }
        throw cmd.error;
    }
    cmd = spawnSync(
        "./bin/ledgersmb-admin",
        [
            "user",
            "create",
            `${pg_user}@${pg_host}/${company}#xyz`,
            `--username=${username}`,
            `--password=${password}`,
            "--employeenumber=1",
            "--country=Canada",
            `--first-name=${username}`,
            `--last-name=${password}`,
            "--permission='Full Permissions'"
        ],
        {
            cwd: process.env.PWD + "/.."
        }
    );
    if (cmd.status !== 0) {
        throw new Error(cmd.stderr.toString());
    }
    if (cmd.error) {
        if (typeof cmd.error === "string") {
            cmd.error = new Error(cmd.error);
        }
        throw cmd.error;
    }
}

export function load_coa(username, password, company, coa) {
    let cmd = spawnSync(
        "./bin/ledgersmb-admin",
        ["setup", "load", `${pg_user}@${pg_host}/${company}#xyz`, coa],
        {
            cwd: process.env.PWD + "/.."
        }
        );
    if (cmd.status !== 0) {
        throw new Error(cmd.stderr.toString());
    }
    if (cmd.error) {
        if (typeof cmd.error === "string") {
            cmd.error = new Error(cmd.error);
        }
        throw cmd.error;
    }
}

export function initialize(company, file) {
    let cmd = spawnSync(
        "psql",
        [
            `--username=${pg_user}`,
            `--host=${pg_host}`,
            "-d", company,
            "-c", "set search_path='xyz','public'",
            "-f", file
        ],
        {
            cwd: process.env.PWD + "/..",
            env: {
                ...process.env,
                PG_PASSWORD: pg_pwd,
                PERL5OPT: ''
            }
        }
        );
    if (cmd.status !== 0) {
        throw new Error(cmd.stderr.toString());
    }
    if (cmd.error) {
        if (typeof cmd.error === "string") {
            cmd.error = new Error(cmd.error);
        }
        throw cmd.error;
    }
}

export function drop_database(company) {
    let cmd = spawnSync(
        "dropdb",
        [company],
        {
            env: {
                ...process.env,
                PERL5OPT: ''
            }
        }
    );
    if (cmd.status !== 0) {
        throw new Error(cmd.stderr.toString());
    }
    if (cmd.error) {
        if (typeof cmd.error === "string") {
            cmd.error = new Error(cmd.error);
        }
        throw cmd.error;
    }
}
