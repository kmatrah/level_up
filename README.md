# LevelUp: a Rails engine to keep your startup technical business organized.

##[Documentation](http://kmatrah.github.com/level_up)

## What ?

If you are building a web app, chances are good you have some jobs to design and execute in order to provide services to your customers.
Generally, that means handling computer-based or manual tasks, calls to external services, failures, timers and retries.
LevelUp lets you build all of these and compose them to create a runnable job. Concretely, you will define a task graph, where each task contains
its own business logic implemented in ruby. Jobs can be performed synchronously in the current thread or asynchronously by background workers.
Three methods are available in each state to control the job flow: move_to!(task_name), retry_in!(delay), manual_task!(task_description).

## Why use LevelUp ?

Designing your jobs graphically with tasks and transitions can be more easier than directly writing code, especially for non-technical people.
Graphs can be drawn, printed, shared and analysed making it easier to let everyone know what the system is doing at specific points in time.
From a developers point of view, it’s clearer to separate the different parts of a job into isolated states. Class-based tasks are reusable
in multiple jobs to avoid code duplication. For example, you can use the Template design pattern to implement the generic part of a task
in a parent class and implement specialized parts in children classes.

## Requirements
Ruby 1.9+, Rails 3.2.x, ActiveRecord, DelayedJob 3.x

## Installation

Add LevelUp to your Gemfile:

```ruby
gem 'level_up'
```

and run `bundle install` within your app's directory.

## Run Migrations

First, make sure DelayedJob migration is installed. If not:

```bash
$ rails g delayed_job:active_record
```

Install and run LevelUp migration:

```bash
$ rake level_up:install:migrations
$ rake db:migrate
```

## Mount the engine

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # ...
  mount LevelUp::Engine => "/level_up"
end
```

## Authentication

LevelUp only provide basic http authentication through Rails 3.1+ <em>http_basic_authenticate_with</em> method. Authentication is disabled by
default. To enable it, add these lines in your config/environments/*.rb.

```ruby
# config/environments/*.rb
config.level_up.http_authentication = true
config.level_up.http_login = "your-login"
config.level_up.http_password = "your-password"
```

## Writing Job Models

```ruby
# app/models/hard_job.rb
class HardJob < LevelUp::Job
  # tasks and transitions
  job do
    task :start, transitions: :first_task
    task :first_task, transitions: :second_task
    task :second_task, transitions: :end
  end

  def first_task
    # logic goes here
  end

  def second_task
    # logic goes here
  end
end
```

### Task classes

You can also define task logic in a class instead of a method.

```ruby
app/models/hard_job/first_task.rb
module HardJob
  class FirstTask < LevelUp::Task
    def run
      # logic goes here
    end
  end
end
```

```ruby
app/models/hard_job/second_task.rb
module HardJob
  class SecondTask < LevelUp::Task
    def run
      # logic goes here
    end
  end
end
```

### Flow control

Inside a task, you can call 3 methods to control the job flow:

#### move_to!(task_name)

Leave the current task and run the specified one.
```ruby
# example:
move_to! :second_task
```

#### retry_in!(delay)

Stop the execution and enqueue a new delayed_job to re-run the current task after the specified delay in seconds.

```ruby
# example:
retry_in! 1.hour
```

#### manual_task!(description)
Stop the execution and set the manual_task and manual_task_description attributes to notify that some work need to be done manually.

```ruby
# example:
manual_task! "check payment information"
```

You can also raise a StandardError (or a subclass) to stop the execution and set the error attribute.
The time, the task and the error backtrace will be saved.

## Running Jobs
In your code:

```ruby
job = HardJob.create(key: "job-key")

# execute the job synchronously
job.boot

# or asynchronously with DelayedJob
job.boot_async!
```

## Todo
- Others authentication methods
- More metrics and filters in the dashboard
- Remove the dependency on DelayedJob to allow the use of others asynchronous queue systems like Resque, Sidekiq or Beanstalk
- Allow graphical interaction on SVG graphs to manage jobs
- ...

## Contributing to LevelUp

Your feedback is very welcome and will make this gem much much better for you, me and everyone else.
Besides feedback on code, features, suggestions and bug reports, you may want to actually make an impact on the code. For this:

- Fork it.
- Fix it.
- Test it.
- Commit it.
- Send me a pull request.

## Contact

Feel free to ask questions using these contact details:
- email: karim.matrah@gmail.com
- twitter: @kmatrah

## Copyright

Copyright 2013 Karim Matrah. See LICENSE.txt for further details.