# LevelUp: a Rails engine to keep your startup technical business organized.

##[Documentation](http://kmatrah.github.com/level_up)

## What ?

If you are building a web app, chances are good you have some jobs to design and execute in order to provide services to your customers.
Generally, that means handling automated tasks, manual human tasks, calls to external services, failures, timers and retries.
LevelUp lets you build all of these and compose them to create a runnable job. Concretely, you will define a state graph, where each state
represents a task and contains its own business logic implemented in ruby. Jobs can be performed synchronously in the
current thread or asynchronously by background workers. Three methods are available in each state to control the job flow: move_to(new_state), retry_in(delay), manual_task(task_description).

## Why use LevelUp ?

Designing your jobs graphically with states and transitions can be more easier than directly writing code, especially for non-technical people.
Graphs can be drawn, printed, shared and analysed making it easier to let everyone know what the system is doing at specific points in time.
From a developers point of view, it’s clearer to separate the different parts of a job into isolated states. Class based states are reusable
in multiple jobs to avoid code duplication. For example, you can use the Template design pattern to implement the generic part of a state
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
# app/jobs/hard_job.rb
class HardJob < LevelUp::Job
  # states and transitions
  job do
    state :start, moves_to: :first_task
    state :first_task, moves_to: :second_task
    state :second_task, moves_to: :end
  end

  def first_task
    # logic goes here
  end

  def second_task
    # logic goes here
  end
end
```

### State objects

You can also define state logic in a class instead of a method.

```ruby
app/jobs/hard_job/first_task.rb
module HardJob
  class FirstTask < LevelUp::State
    def run
      # logic goes here
    end
  end
end
```

```ruby
app/jobs/hard_job/second_task.rb
module HardJob
  class SecondTask < LevelUp::State
    def run
      # logic goes here
    end
  end
end
```

### Flow control

Inside a state, you can call 3 methods to control the job flow:

#### move_to(state_name)

Leave the current state and run the specified state.
```ruby
# example:
move_to :second_task
```

#### retry_in(delay)

Stop the execution and queue a new delayed_job to re-run the current state after the specified delay in seconds.

```ruby
# example:
retry_in 1.hour
```

#### task(description)
Stop the execution and set the task and task_description attributes to notify a manual human intervention.

```ruby
# example:
task "check payment information"
```

You can also raise a StandardError (or a subclass) to stop the execution and set the error attribute.
The time, the state and the error backtrace will be saved.

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