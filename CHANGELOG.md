# CHANGELOG

## 1.4.0 - released 2015-01-15

### `git pair-commit` explicitly sets the author name
    
Before this change, git's user.name setting would override. In
repositories where the user had previously run `git duet`, this meant
that after a `git pair --global ...` the email was set correctly by `git
pair-commit`, but the author name was not.

[#62606550]

### `git pair-commit` sets committer name and email
    
[Finishes #62606550]

### Add ability to use a custom email address per user

    # include the following section to set custom email addresses for users
    email_addresses:
      zr: zach.robinson@example.com

### Include the $HOME directory if it's not in the list of pwd ancestors.

This fixes the actual behavior to match the documentation, which states that the `.pairs` file may be in the user's home directory.
