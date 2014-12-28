' Credit: https://raw.githubusercontent.com/dphang/roku-lib/master/RokuLib/util/SortUtils.brs

'Sorts an array using a stable merge sort
'@param array the array to sort
'@param the comparator to use
function RlMergeSort(array as Object, comparator = invalid as Dynamic) as Void
    if comparator = invalid then comparator = RlSort_AscendingComparator
    
    length = array.Count()
    if length > 1
        left = []
        right = []
        
        middle = int(length / 2)
        
        for i = 0 to middle - 1
            left[i] = array[i]
        end for
        
        for i = middle to length - 1
            right[i - middle] = array[i]
        end for
        
        RlMergeSort(left, comparator)
        RlMergeSort(right, comparator)
        
        i = 0
        j = 0
        k = 0
        
        length1 = left.Count()
        length2 = right.Count()
        
        'Merge
        while length1 <> j and length2 <> k
            if comparator(left[j], right[k]) < 0
                array[i] = left[j]
                i = i + 1
                j = j + 1
            else
                array[i] = right[k]
                i = i + 1
                k = k + 1
            end if
        end while
        
        while length1 <> j
            array[i] = left[j]
            i = i + 1
            j = j + 1
        end while
        
        while length2 <> k
            array[i] = right[k]
            i = i + 1
            k = k + 1
        end while
        'End merge
        
    end if
    
end function

'Sorts an array using an unstable quick sort
function RlQuickSort(array as Object, comparator = invalid as Dynamic) as Void
	if comparator = invalid then comparator = RlSort_AscendingComparator
	
	length = array.Count()
	if length > 1
		RlQuickSort_qsort(array, comparator, 0, length - 1)
	end if
end function

function RlQuickSort_qsort(array as Object, comparator as Dynamic, left as Integer, right as Integer)
	if left < right
		pivot = left + int(Rnd(0) * (right - left))
		
		'Partition
        pivotValue = array[pivot]
        ArraySwap(array, pivot, right)
        
        store = left
        
        for i = left to right - 1
            if comparator(array[i], pivotValue) < 0
                ArraySwap(array, store, i)
                store = store + 1
            end if
        end for
        
        ArraySwap(array, right, store)
        
        pivot = store
        'End partition
		
		RlQuickSort_qsort(array, comparator, left, pivot - 1)
		RlQuickSort_qsort(array, comparator, pivot + 1, right)	
	end if
end function

'Sorts an array using a stable insertion sort
'@param array the array to sort
'@param the comparator to use
function RlInsertionSort(array as Object, comparator = invalid as Dynamic) as Void
    if comparator = invalid then comparator = RlSort_AscendingComparator
    
    max = array.Count() - 1
    for i = 0 to max
    	temp = array[i]
    	hole = i
    	
    	while hole > 0 and comparator(temp, array[hole - 1]) < 0
    		array[hole] = array[hole - 1]
    		hole = hole - 1
    	end while

    	array[hole] = temp
    end for
end function

'Ascending comparator for two values in an array
'@param a the first element
'@param b the second element
'@return -1 if a < b, otherwise 1
function RlSort_AscendingComparator(a as Dynamic, b as Dynamic) as Integer
    if a < b
        return -1
    else
        return 1
    end if
end function

'Descending comparator for two values in an array
'@param a the first element
'@param b the second element
'@return -1 if a < b, otherwise 1
function RlSort_DescendingComparator(a as Dynamic, b as Dynamic) as Integer
    if a > b
        return -1
    else
        return 1
    end if
end function