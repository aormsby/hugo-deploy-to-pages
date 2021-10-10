# Github Action: Hugo Deploy

[![Open in Visual Studio Code](https://open.vscode.dev/badges/open-in-vscode.svg)](https://open.vscode.dev/aormsby/hugo-deploy-to-pages)

An action for building Hugo websites. Build your site from a source branch and deploy on a release branch.

This action supports deploying to the same repository or pushing build data to a submodule. It's great for automating Hugo site builds and maintaining a separate release branch.

## Updates in v2

[See wiki for more info on these changes.](https://github.com/aormsby/hugo-deploy-to-pages/wiki))

- New release pattern - v1 pushed changes to the source branch, v2 pushes changes to a release branch
- Added test mode - runs key checks on your input values to help you verify your action configuration before running live!
- Fixed git configuration - config now set only if empty to avoid conflicts with other job steps
- Cleanup - the main deploy script was separated into multiple scripts for better maintainability

<a href="https://www.buymeacoffee.com/aormsby" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-green.png" alt="Buy Me A Coffee" style="height: 51px !important;width: 217px !important;" ></a>

## How to Use

[Add a workflow](https://docs.github.com/en/actions/quickstart#creating-your-first-workflow) to your repo that includes this action ([sample below](#sample-workflow)). Please note that scheduled workflows only run on the default branch of a repo.

For git checkout, I use [actions/checkout](https://github.com/actions/checkout).(A token or SSH is needed for checking out private submodule repos.) For installing Hugo on the runner, I use [peaceiris/actions-hugo](https://github.com/peaceiris/actions-hugo).

### Input Variables

**Note:** For clarity reasons, some variable names have been changed a bit between v1 and v2. Please check your workflows for the correct input.

#### Core Use

| Name                     |     Required?      | Default  | Example     |
| ------------------------ | :----------------: | -------- | ----------- |
| hugo_publish_directory   | :white_check_mark: | 'public' | 'documents' |
| source_branch            | :white_check_mark: |          | 'main'      |
| release_branch           | :white_check_mark: |          | 'release'   |
| submodule_release_branch |                    |          | 'main'      |

#### Advanced Use (see [wiki](https://github.com/aormsby/hugo-deploy-to-pages/wiki/Configuration) for further details)

| Name                 | Default                 | Example                                |
| -------------------- | ----------------------- | -------------------------------------- |
| hugo_build_options   |                         | '-D --minify --ignoreCache'            |
| merge_args           | '-s recursive -Xtheirs' | '-X Ours'                              |
| full_rebuild         | 'false'                 |                                        |
| full_rebuild_verbose | 'false'                 |                                        |
| do_not_delete_regex  |                         | '\\\.txt\|\^posts\$\|static.css'       |
| commit_message       |                         | 'I like big builds, and I cannot lie.' |
| git_config_user      | 'Action - Hugo Deploy'  | 'aormsby'                              |
| git_config_email     | 'action@github.com'     | 'GeronimoJones@g.woah'                 |
| strict_build_mode    | 'true'                  |                                        |
| tag_release          | 'false'                 |                                        |
| test_mode            | 'false'                 |                                        |

#### Git Config Settings

Some basic git config settings must be in place to pull and push data during the action. As seen above, these inputs are required and have default values. They are reset when this action step is finished.

### Output Variables

| Name                  | Output     | Description                                                                              |
| --------------------- | ---------- | ---------------------------------------------------------------------------------------- |
| was_new_build_created | true/false | Outputs true if a new build was made, false if repo is up-to-date and build was skipped. |

Want more output variables? [Open an issue](https://github.com/aormsby/hugo-deploy-to-pages/issues) and let me know.

## Sample Workflow

### Deploying to a live site with simple settings

```yaml
on:
  schedule:
    - cron:  '0 7 * * 1,4'
    # scheduled at 07:00 every Monday and Thursday
  workflow_dispatch:
    # to run manual builds

jobs:
  build_and_deploy_hugo_site:
    runs-on: ubuntu-latest
    name: Build and deploy Hugo site

    steps:
    - name: Setup Hugo
      uses: peaceiris/actions-hugo@v2
      with:
        hugo-version: '0.88.1'
    
    - name: Checkout repo on source_branch
      uses: actions/checkout@v2
      with:
        submodules: 'recursive'
        # <<recommended if project uses git submodules for any purpose>>
        # <<required if deploying to git submodule directory>>
        token: ${{ secrets.MY_SECRET }}   # <<if needed for private repos>>
        fetch-depth: '0'
        # <<fetch-depth: '0' currently required until shallow clone problems are solved>>
        
    - name: Build site and push to release branch
      uses: aormsby/hugo-deploy-to-pages@v2
      id: build_step  # <<for outputs>>
      with:
        source_branch: 'main'
        release_branch: 'bon-voyage'
        # submodule_release_branch: 'subbed' <<only provide if you are publishing to directory with git submodule>>
        # full_rebuild: true
        # hugo_publish_directory: 'documents'   <<publish to another directory if needed>>
        # hugo_build_options: '-D --minify --ignoreCache' <<hugo build cis customizable>>
        # commit_message: "I love this action."
        # test_mode: true <<enable to run a few verification tests before your first live run>>

        # <<lots of other options!>>

    - name: Check if new build was made
      if: steps.build.outputs.was_new_build_created == 'true'
      run: echo "YAAASSSS new build."
      if: steps.build.outputs.was_new_build_created == 'false'
      run: echo "NOOOOOOO new build."
```
