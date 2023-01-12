# helm-docs GitHub Actions

A Github action for generating Helm module documentation using helm-docs .
Fork from : https://github.com/norwoodj/helm-docs


## Usage

```yaml
name: Generate helm docs
on:
  - pull_request
jobs:
  docs:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
      with:
        ref: ${{ github.event.pull_request.head.ref }}

    - name: Render helm docs inside the README.md and push changes back to PR branch
      uses: shaybentk/helm-docs-action@v0.0.1
      with:
        working-dir: mychart
        git-push: "true"
```


### Inputs

| Name | Description | Default | Required |
|------|-------------|---------|----------|
| fail-on-diff | Fail the job if there is any diff found between the generated output and existing file (ignored if `git-push` is set) | `false` | false |
| git-commit-message | Commit message | `helm-docs: automated action` | false |
| git-push | If true it will commit and push the changes | `false` | false |
| git-push-sign-off | If true it will sign-off commit | `false` | false |
| git-push-user-email | If empty the no-reply email of the GitHub Actions bot will be used (i.e. `github-actions[bot]@users.noreply.github.com`) | `""` | false |
| git-push-user-name | If empty the name of the GitHub Actions bot will be used (i.e. `github-actions[bot]`) | `""` | false |
| output-file | File in module directory where the docs should be placed | `README.md` | false |
| working-chart | Name of directory to generate docs for  | `.` | false |
| working-dir | Comma separated list of directories to generate docs for  | `.` | false |


#### Auto commit changes

To enable you need to ensure a few things first:

- set `git-push` to `true`
- use `actions/checkout@v3` with the head ref for PRs or branch name for pushes
  - PR

    ```yaml
    on:
      - pull_request
    jobs:
      docs:
        runs-on: ubuntu-latest
        steps:
        - uses: actions/checkout@v3
          with:
            ref: ${{ github.event.pull_request.head.ref }}
    ```

  - Push

    ```yaml
    on:
      push:
        branches:
          - master
    jobs:
      docs:
        runs-on: ubuntu-latest
        steps:
        - uses: actions/checkout@v3
          with:
            ref: master
    ```
## Examples

### Single folder

```yaml
- name: Generate Helm Docs
  uses: shaybentk/helm-docs-action@v0.0.1
  with:
    working-dir: mychart
    git-push: "true"
```

### Multi folder

```yaml
- name: Generate Helm Docs
  uses: shaybentk/helm-docs-action@v0.0.1
  with:
    working-dir: mychart1,mychart2,mychart3
    git-push: "true"
```

