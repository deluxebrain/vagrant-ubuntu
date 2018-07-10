# TODO

- Sidecar installer ( as opposed to manual git submodule add )
- Shares and file exlusions:

  ``` ruby
  config.user.sharing.shares.each do |key, value|
    config.vm.synced_folder File.expand_path(value[:source]),
      value[:destination],
      type: "rsync",
      rsync__exclude: ".git/"
  end
  ```

- AWS and MFA

- Azure support
- Windows WSL support
