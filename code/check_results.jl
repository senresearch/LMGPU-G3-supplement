using CSV
using DataFrames

function check_results(rqtl_result::DataFrame, julia_result::DataFrame; maxlod = true)
    #remove row name column. 
    if maxlod 
        rqtl_max = Matrix(rqtl_result)
        julia_max = Matrix(julia_result)
    else 
        rqtl_float = rqtl_result |> Matrix |> transpose |> collect
        rqtl_max = find_max_idx_value(rqtl_float)

        julia_float = julia_result |> Matrix 
        julia_max = find_max_idx_value(julia_float)
    end

    for i in size(julia_max)[1]
        # compare value first 
        if !isapprox(rqtl_max[i,2], julia_max[i,2], atol=1e-5)
            @info "Scan result does not agree at row:$i, rqtl: $(rqtl_max[i,2]), julia: $(julia_max[i,2])"
            return;
        end

        # then compare index 
        if rqtl_max[i, 1] != julia_max[i,1]
            print("Scan result index is different, rqtl result is at index: $(rqtl_max[i, 1]), julia result is at index: $(julia_max[i,1])")
        end

    end
    println("Result check finished. ")
end


function find_max_idx_value(lod::AbstractArray{<:Real,2})
    max_array = Array{typeof(lod[1,1]),2}(undef, size(lod)[1], 2)
    Threads.@threads for i in 1:size(lod)[1]
        temp = lod[i, 1]
        idx = 1
        for j in 2:size(lod)[2]
            if temp < lod[i,j]
                temp = lod[i,j]
                idx = j
            end
        end
        max_array[i,1] = idx
        max_array[i,2] = temp
    end
    return max_array
end


for datatype in [Float64, Float32]
    for dataset in ["spleen", "hippo"]
        println("Checking result for $dataset")
        rqtl_result_file = joinpath(Base.@__DIR__, "..", "data", "results", dataset*"_rqtl_lod_score.csv")
        julia_result_file = joinpath(Base.@__DIR__, "..", "data", "results", string(datatype) * dataset*"_lmgpu_output.csv")
        
        rqtl_result =  CSV.read(rqtl_result_file, datarow=2)
        julia_result = CSV.read(julia_result_file, datarow=1)

        check_results(rqtl_result, julia_result)
    end
end


