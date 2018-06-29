class StartContainer
  include Sidekiq::Worker
  sidekiq_options :retry => 5

  sidekiq_retry_in do |count|
    count + 1
  end

  def perform(container_name)
    container = lxc_client.container(container_name)
    start_interval = Time.now() - container[:created_at]
    if start_interval > Figaro.env.WAIT_INTERVAL_FOR_STARTING_CONTAINER.to_i
      if container[:status] != "Running"
        lxc_client.start_container(container_name)
      end
    else
      raise Exception.new("Container #{container_name} is still being created")
    end
  end

  private

  def lxc_client
    Lxd.client_object(ContainerHost.first.ipaddress)
  end
end
