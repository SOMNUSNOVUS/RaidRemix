function RaidJobManager:_set_selected_job(job_id)
	local selected_job = tweak_data.operations:mission_data(job_id)
	self._current_job = nil

	managers.statistics:stop_session({
		success = false,
		quit = true
	})
	managers.network:session():send_to_peers_synched("stop_statistics_session", false, true, "")

	self._selected_job = selected_job
	self._loot_data = {}

	managers.global_state:reset_all_flags()
	managers.groupai:state():set_job_id(job_id)

	if self._selected_job.job_type == OperationsTweakData.JOB_TYPE_RAID then
		self:_select_raid()
		managers.global_state:set_flag(selected_job.mission_flag)
	elseif self._selected_job.job_type == OperationsTweakData.JOB_TYPE_OPERATION then
		self:_select_operation()
		managers.global_state:set_flag(selected_job.current_event_data.mission_flag)
	end
end

function RaidJobManager:cleanup()
	self._current_save_slot = {}
	self._selected_job = nil
	self._current_job = nil
	self._stage_success = nil
	self._loot_data = {}
	self._tutorial_spawned = nil
	managers.groupai:state():set_job_id("streaming_level")
end